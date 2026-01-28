import 'package:flutter/material.dart';
import 'package:queless/screens/home/home_screen.dart';
import 'package:queless/screens/food/food_home_screen.dart';
import 'package:queless/screens/cart/cart_screen.dart';
import 'package:queless/screens/orders/orders_screen.dart';
import 'package:queless/screens/profile/profile_screen.dart';
import 'package:queless/services/cart_service.dart';
import 'package:queless/services/food_cart_service.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final _alcoholCartService = CartService();
  final _foodCartService = FoodCartService();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _alcoholCartService.addListener(_onCartChanged);
    _foodCartService.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _alcoholCartService.removeListener(_onCartChanged);
    _foodCartService.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() => setState(() {});

  int get _totalCartCount => _alcoholCartService.itemCount + _foodCartService.itemCount;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const FoodHomeScreen(),
      const CartScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.local_bar_outlined),
              selectedIcon: Icon(Icons.local_bar),
              label: 'Alcohol',
            ),
            const NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant),
              label: 'Food',
            ),
            NavigationDestination(
              icon: Badge(
                label: Text('$_totalCartCount'),
                isLabelVisible: _totalCartCount > 0,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: Badge(
                label: Text('$_totalCartCount'),
                isLabelVisible: _totalCartCount > 0,
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Orders',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
