import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/location_service.dart';
import 'package:queless/services/food_cart_service.dart';
import 'package:queless/screens/auth/permission_request_screen.dart';
import 'package:queless/screens/home/store_card.dart';
import 'package:queless/screens/food/store_detail_screen.dart';
import 'package:queless/models/promotion.dart';
import 'package:queless/services/product_service.dart';
import 'package:queless/services/promotion_service.dart';
import 'package:queless/screens/product/product_detail_screen.dart';
import 'package:queless/widgets/promotion_modal.dart';
import 'package:queless/widgets/promo_badge.dart';

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  final _storeService = StoreService();
  final _authService = AuthService();
  final _locationService = LocationService();
  final _promotionService = PromotionService();
  final _productService = ProductService();
  final _searchController = TextEditingController();
  List<Store> _stores = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _checkPermissionsBeforeLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsBeforeLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsRequested =
        prefs.getBool('permissions_requested') ?? false;

    if (!permissionsRequested) {
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PermissionRequestScreen()),
        );
        // After returning, try to load stores
        _loadStores();
      }
    } else {
      _loadStores();
    }
  }

  List<Store> _getFilteredStores() {
    return _stores.where((store) {
      final matchesCategory = _selectedCategory == 'All' ||
          store.cuisineTypes.any(
              (type) => type.toLowerCase() == _selectedCategory.toLowerCase());

      final matchesSearch = _searchQuery.isEmpty ||
          store.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          store.cuisineTypes.any((type) =>
              type.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
    });

    try {
      // 1. Get current location
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        // 2. Fetch nearby stores if location available
        debugPrint(
            '📍 Fetching stores near ${position.latitude}, ${position.longitude}');
        final stores = await _storeService.getNearbyStores(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusMeters: 5000, // 5km radius
          category: 'restaurant',
        );

        var finalStores = stores;
        if (stores.isEmpty) {
          // Try 10km radius if no stores within 5km
          finalStores = await _storeService.getNearbyStores(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusMeters: 10000, // 10km radius
            category: 'restaurant',
          );
        }

        if (mounted) {
          setState(() {
            _stores = finalStores;
            _isLoading = false;
          });

          // Update distances in food cart service for fee calculation
          for (final store in finalStores) {
            if (store.distance != null) {
              FoodCartService().updateStoreDistance(store.id, store.distance!);
            }
          }
        }
        await _promotionService.refreshActivePromotions();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeShowPromotion();
        });
      } else {
        // Fallback to all open food stores if location denied/unavailable
        debugPrint('⚠️ Location unavailable, falling back to all food stores');
        final stores = await _storeService.getStores(category: 'restaurant');
        setState(() {
          _stores = stores;
          _isLoading = false;
          _locationError = 'Location unavailable. Showing all food stores.';
        });
        await _promotionService.refreshActivePromotions();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _maybeShowPromotion();
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _loadStores: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _maybeShowPromotion() async {
    final promo = _promotionService.featuredPromotion;
    if (promo == null) return;
    if (!await _promotionService.shouldShowPromotionModal()) return;
    if (!context.mounted) return;

    final rootContext = context;
    await showDialog<void>(
      context: rootContext,
      builder: (dialogContext) => PromotionModal(
        promotion: promo,
        onDismiss: () => Navigator.pop(dialogContext),
        onView: () async {
          Navigator.pop(dialogContext);
          if (!rootContext.mounted) return;

          if (promo.targetType == PromotionTargetType.store) {
            final store = await _storeService.getStoreById(promo.targetId);
            if (!rootContext.mounted || store == null) return;
            await Navigator.push(
              rootContext,
              MaterialPageRoute(
                builder: (_) => StoreDetailScreen(store: store),
              ),
            );
            return;
          }

          final product = await _productService.getProductById(promo.targetId);
          if (!rootContext.mounted || product == null) return;
          await Navigator.push(
            rootContext,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
      ),
    );

    await _promotionService.markPromotionModalShown();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.restaurant, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Food Delivery'),
          ],
        ),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStores,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Hello, ${user?.fullName.split(' ').first ?? 'Guest'}!',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('What would you like to eat today?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7))),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search restaurants or cuisines...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    CategoryChips(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nearby Restaurants',
                                style: theme.textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            if (_locationError != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _locationError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FutureBuilder<bool>(
                                future: _locationService.hasPermission(),
                                builder: (context, snapshot) {
                                  if (snapshot.data == false) {
                                    return FilledButton.icon(
                                      onPressed: () async {
                                        final granted = await _locationService
                                            .requestPermission();
                                        if (granted) {
                                          _loadStores();
                                        }
                                      },
                                      icon: const Icon(Icons.location_on),
                                      label:
                                          const Text('Allow Location Access'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ),
                        if (_locationError != null)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadStores,
                            tooltip: 'Retry Location',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_stores.isNotEmpty &&
                        _stores.every((s) => (s.distance ?? 0) > 5000))
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.secondary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: theme.colorScheme.secondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No stores within 5km. Showing nearby options within 10km. Delivery fee: R45.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _getFilteredStores().isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.3)),
                                  const SizedBox(height: 16),
                                  Text(
                                      _searchQuery.isNotEmpty
                                          ? 'No restaurants found for "$_searchQuery"'
                                          : _stores.isEmpty
                                              ? 'No restaurants available'
                                              : 'No restaurants found for $_selectedCategory',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                              color: theme.colorScheme.onSurface
                                                  .withValues(alpha: 0.5))),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _getFilteredStores().length,
                            itemBuilder: (context, index) =>
                                StoreCard(store: _getFilteredStores()[index]),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      'Fast Food',
      'Pizza',
      'Burgers',
      'Asian',
      'Desserts'
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => onCategorySelected(category),
            ),
          );
        },
      ),
    );
  }
}
