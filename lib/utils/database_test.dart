import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Database connection test utility
/// Use this to verify Supabase connection and table access
class DatabaseTest {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Test database connection and table access
  Future<void> runAllTests() async {
    debugPrint('🔍 Starting Database Connection Tests...');
    debugPrint('━' * 50);
    
    await _testConnection();
    await _testUsersTable();
    await _testProductsTable();
    await _testCartsTable();
    await _testOrdersTable();
    await _testPaymentsTable();
    
    debugPrint('━' * 50);
    debugPrint('✅ Database Tests Completed!');
  }

  /// Test basic connection
  Future<void> _testConnection() async {
    try {
      debugPrint('\n📡 Testing Supabase Connection...');
      final response = await _supabase.rpc('ping').timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('Connection timeout'),
      );
      debugPrint('✅ Connection: SUCCESS');
    } catch (e) {
      // Even if ping fails, we can still test tables
      debugPrint('⚠️  Connection: Could not verify (but may still work)');
      debugPrint('   Error: $e');
    }
  }

  /// Test users table
  Future<void> _testUsersTable() async {
    try {
      debugPrint('\n📊 Testing public.users table...');
      
      final response = await _supabase
          .from('users')
          .select()
          .limit(1);
      
      debugPrint('✅ Users table: ACCESSIBLE');
      debugPrint('   Schema: public.users');
      debugPrint('   Records found: ${response.length}');
      if (response.isNotEmpty) {
        debugPrint('   Sample columns: ${response.first.keys.join(', ')}');
      }
    } catch (e) {
      debugPrint('❌ Users table: FAILED');
      debugPrint('   Error: $e');
    }
  }

  /// Test products table
  Future<void> _testProductsTable() async {
    try {
      debugPrint('\n📊 Testing public.products table...');
      
      final response = await _supabase
          .from('products')
          .select()
          .limit(5);
      
      debugPrint('✅ Products table: ACCESSIBLE');
      debugPrint('   Schema: public.products');
      debugPrint('   Records found: ${response.length}');
      if (response.isNotEmpty) {
        debugPrint('   Sample columns: ${response.first.keys.join(', ')}');
        debugPrint('   Sample product: ${response.first['name']}');
      } else {
        debugPrint('⚠️  Table is empty. Run insert_products.sql to add data.');
      }
    } catch (e) {
      debugPrint('❌ Products table: FAILED');
      debugPrint('   Error: $e');
    }
  }

  /// Test carts table
  Future<void> _testCartsTable() async {
    try {
      debugPrint('\n📊 Testing public.carts table...');
      
      final response = await _supabase
          .from('carts')
          .select()
          .limit(1);
      
      debugPrint('✅ Carts table: ACCESSIBLE');
      debugPrint('   Schema: public.carts');
      debugPrint('   Records found: ${response.length}');
    } catch (e) {
      debugPrint('❌ Carts table: FAILED');
      debugPrint('   Error: $e');
    }
  }

  /// Test orders table
  Future<void> _testOrdersTable() async {
    try {
      debugPrint('\n📊 Testing public.orders table...');
      
      final response = await _supabase
          .from('orders')
          .select()
          .limit(1);
      
      debugPrint('✅ Orders table: ACCESSIBLE');
      debugPrint('   Schema: public.orders');
      debugPrint('   Records found: ${response.length}');
    } catch (e) {
      debugPrint('❌ Orders table: FAILED');
      debugPrint('   Error: $e');
    }
  }

  /// Test payments table
  Future<void> _testPaymentsTable() async {
    try {
      debugPrint('\n📊 Testing public.payments table...');
      
      final response = await _supabase
          .from('payments')
          .select()
          .limit(1);
      
      debugPrint('✅ Payments table: ACCESSIBLE');
      debugPrint('   Schema: public.payments');
      debugPrint('   Records found: ${response.length}');
    } catch (e) {
      debugPrint('❌ Payments table: FAILED');
      debugPrint('   Error: $e');
    }
  }

  /// Quick test - just check if products can be fetched
  static Future<void> quickTest() async {
    try {
      debugPrint('🔍 Quick Database Test...');
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .limit(3);
      
      debugPrint('✅ Database connection working!');
      debugPrint('   Products found: ${response.length}');
      if (response.isNotEmpty) {
        for (var product in response) {
          debugPrint('   - ${product['name']} (R${product['price']})');
        }
      }
    } catch (e) {
      debugPrint('❌ Database test failed: $e');
    }
  }
}
