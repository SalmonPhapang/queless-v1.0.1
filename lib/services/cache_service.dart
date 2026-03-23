import 'package:queless/logger.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      Logger.debug('CACHE HIT: $key');
      return entry.data as T?;
    }
    Logger.debug('CACHE MISS: $key');
    return null;
  }

  void set(String key, dynamic data,
      {Duration duration = const Duration(minutes: 10)}) {
    Logger.debug('CACHE SET: $key for ${duration.inMinutes} minutes');
    _cache[key] = _CacheEntry(data, DateTime.now().add(duration));
  }

  void invalidate(String key) {
    Logger.debug('CACHE INVALIDATE: $key');
    _cache.remove(key);
  }

  void clear() {
    Logger.debug('CACHE CLEAR: All entries removed');
    _cache.clear();
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  _CacheEntry(this.data, this.expiryTime);

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
