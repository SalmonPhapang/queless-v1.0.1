import 'package:flutter/material.dart';
import 'package:queless/models/store.dart';
import 'package:queless/services/store_service.dart';
import 'package:queless/services/auth_service.dart';
import 'package:queless/services/location_service.dart';
import 'package:queless/screens/food/store_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  final _storeService = StoreService();
  final _authService = AuthService();
  final _locationService = LocationService();
  List<Store> _stores = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  List<Store> _getFilteredStores() {
    if (_selectedCategory == 'All') {
      return _stores;
    }
    return _stores.where((store) {
      return store.cuisineTypes
          .any((type) => type.toLowerCase() == _selectedCategory.toLowerCase());
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
          radiusMeters: 5000, // 5km range
        );

        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      } else {
        // Fallback to all open stores if location denied/unavailable
        debugPrint('⚠️ Location unavailable, falling back to all open stores');
        final stores = await _storeService.getOpenStores();
        setState(() {
          _stores = stores;
          _isLoading = false;
          _locationError = 'Location unavailable. Showing all stores.';
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _loadStores: $e');
      setState(() => _isLoading = false);
    }
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
        actions: [
          IconButton(icon: const Icon(Icons.search_outlined), onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
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
                            if (_locationError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _locationError!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error),
                                ),
                              ),
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
                    _getFilteredStores().isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Text(
                                  _stores.isEmpty
                                      ? 'No restaurants available'
                                      : 'No restaurants found for $_selectedCategory',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5))),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _getFilteredStores().length,
                            itemBuilder: (context, index) =>
                                StoreCard(store: _getFilteredStores()[index]),
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

class StoreCard extends StatelessWidget {
  final Store store;

  const StoreCard({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoreDetailScreen(store: store)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            store.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: store.imageUrl,
                    imageBuilder: (context, imageProvider) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        image: DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    placeholder: (context, url) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                      ),
                      child: Center(
                        child: Icon(Icons.restaurant_menu,
                            size: 64,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3)),
                      ),
                    ),
                  )
                : Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Icon(Icons.restaurant_menu,
                          size: 64,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!store.isOpen)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Closed',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.colorScheme.error)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    store.cuisineTypes.join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${store.rating.toStringAsFixed(1)} (${store.totalReviews})',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.delivery_dining,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${store.deliveryTimeMin}-${store.deliveryTimeMax} min',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
