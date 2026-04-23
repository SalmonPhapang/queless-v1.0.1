import 'dart:convert';
import 'package:queless/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};
  static const String _prefPrefix = 'queless_cache_';
  SharedPreferences? _prefs;
  static const int _maxCacheSize = 200; // Limit in-memory cache size

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadFromPrefs();
  }

  void _loadFromPrefs() {
    if (_prefs == null) return;
    final keys = _prefs!.getKeys();
    
    // Sort keys by modification time if possible, or just take the first N
    // For simplicity, we'll just clear old ones if they are expired
    for (final key in keys) {
      if (key.startsWith(_prefPrefix)) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          try {
            final map = jsonDecode(jsonStr);
            final entry = _CacheEntry.fromJson(map);
            if (!entry.isExpired) {
              _addToMemoryCache(key.replaceFirst(_prefPrefix, ''), entry);
            } else {
              _prefs!.remove(key);
            }
          } catch (e) {
            Logger.debug('Error loading cache entry $key: $e');
          }
        }
      }
    }
    Logger.debug('✅ Cache loaded: ${_cache.length} entries');
  }

  void _addToMemoryCache(String key, _CacheEntry entry) {
    if (_cache.length >= _maxCacheSize && !_cache.containsKey(key)) {
      // Evict oldest entry (the first one in the map)
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = entry;
  }

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry != null) {
      if (!entry.isExpired) {
        Logger.debug('CACHE HIT: $key');
        return entry.data as T?;
      } else {
        // Remove expired entry from both memory and prefs
        invalidate(key);
      }
    }
    Logger.debug('CACHE MISS: $key');
    return null;
  }

  Future<void> set(String key, dynamic data,
      {Duration duration = const Duration(minutes: 60)}) async {
    Logger.debug('CACHE SET: $key for ${duration.inMinutes} minutes');
    final entry = _CacheEntry(data, DateTime.now().add(duration));
    _addToMemoryCache(key, entry);

    if (_prefs != null) {
      try {
        await _prefs!.setString(_prefPrefix + key, jsonEncode(entry.toJson()));
      } catch (e) {
        Logger.debug('Error saving cache entry $key: $e');
      }
    }
  }

  Future<void> invalidate(String key) async {
    Logger.debug('CACHE INVALIDATE: $key');
    _cache.remove(key);
    if (_prefs != null) {
      await _prefs!.remove(_prefPrefix + key);
    }
  }

  Future<void> clear() async {
    Logger.debug('CACHE CLEAR: All entries removed');
    _cache.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith(_prefPrefix)) {
          await _prefs!.remove(key);
        }
      }
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  _CacheEntry(this.data, this.expiryTime);

  Map<String, dynamic> toJson() => {
        'data': data,
        'expiryTime': expiryTime.toIso8601String(),
      };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) => _CacheEntry(
        json['data'],
        DateTime.parse(json['expiryTime']),
      );

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
