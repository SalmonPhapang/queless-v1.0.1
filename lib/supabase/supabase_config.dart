import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:queless/services/connectivity_service.dart';

/// Exception thrown when there's no network connection
class NoNetworkException implements Exception {
  final String message;
  NoNetworkException([this.message = 'No internet connection available']);
  @override
  String toString() => message;
}

/// Generic Supabase configuration template
/// Replace YOUR_ and YOUR_ with your actual values
class SupabaseConfig {
  static final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  static final String anonKey =
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: anonKey,
      debug: kDebugMode,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
}

/// Generic database service for CRUD operations
class SupabaseService {
  /// Check for network connectivity before making calls
  static void _checkConnectivity() {
    if (!ConnectivityService().isConnected) {
      throw NoNetworkException();
    }
  }

  /// Select multiple records from a table
  static Future<List<Map<String, dynamic>>> select(
    String table, {
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      _checkConnectivity();
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      // Apply filters
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query;
    } catch (e) {
      if (e is NoNetworkException) rethrow;
      throw _handleDatabaseError('select', table, e);
    }
  }

  /// Select a single record from a table
  static Future<Map<String, dynamic>?> selectSingle(
    String table, {
    String? select,
    required Map<String, dynamic> filters,
  }) async {
    try {
      _checkConnectivity();
      dynamic query = SupabaseConfig.client.from(table).select(select ?? '*');

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.maybeSingle();
    } catch (e) {
      if (e is NoNetworkException) rethrow;
      throw _handleDatabaseError('selectSingle', table, e);
    }
  }

  /// Insert a record into a table
  static Future<List<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      _checkConnectivity();
      return await SupabaseConfig.client.from(table).insert(data).select();
    } catch (e) {
      if (e is NoNetworkException) rethrow;
      throw _handleDatabaseError('insert', table, e);
    }
  }

  /// Insert multiple records into a table
  static Future<List<Map<String, dynamic>>> insertMultiple(
    String table,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      _checkConnectivity();
      return await SupabaseConfig.client.from(table).insert(data).select();
    } catch (e) {
      if (e is NoNetworkException) rethrow;
      throw _handleDatabaseError('insertMultiple', table, e);
    }
  }

  /// Upsert (insert or update) a record in a table
  static Future<List<Map<String, dynamic>>> upsert(
    String table,
    Map<String, dynamic> data, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      _checkConnectivity();
      // For upsert, we typically don't use manual filters like in update/delete
      // unless we are doing something specific, but Supabase's upsert works on primary keys or unique constraints.
      // However, keeping the signature consistent might be useful, or we just pass data.
      // The Supabase Flutter SDK upsert method takes data and options.
      return await SupabaseConfig.client.from(table).upsert(data).select();
    } catch (e) {
      if (e is NoNetworkException) rethrow;
      throw _handleDatabaseError('upsert', table, e);
    }
  }

  /// Update records in a table
  static Future<List<Map<String, dynamic>>> update(
    String table,
    Map<String, dynamic> data, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      _checkConnectivity();
      dynamic query = SupabaseConfig.client.from(table).update(data);

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      return await query.select();
    } catch (e) {
      if (e is NoNetworkException) rethrow;
      throw _handleDatabaseError('update', table, e);
    }
  }

  /// Delete records from a table
  static Future<void> delete(
    String table, {
    required Map<String, dynamic> filters,
  }) async {
    try {
      _checkConnectivity();
      dynamic query = SupabaseConfig.client.from(table).delete();

      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }

      await query;
    } catch (e) {
      if (e is NoNetworkException) rethrow;
      throw _handleDatabaseError('delete', table, e);
    }
  }

  /// Get direct table reference for complex queries
  static SupabaseQueryBuilder from(String table) =>
      SupabaseConfig.client.from(table);

  /// Handle database errors
  static String _handleDatabaseError(
    String operation,
    String table,
    dynamic error,
  ) {
    if (error is PostgrestException) {
      return 'Failed to $operation from $table: ${error.message}';
    } else {
      return 'Failed to $operation from $table: ${error.toString()}';
    }
  }
}
