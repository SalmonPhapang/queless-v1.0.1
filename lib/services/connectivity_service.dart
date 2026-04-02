import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:queless/utils/logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Initial check
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen to changes
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // connectivity_plus 6.x returns a list of results
    _isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    _connectivityController.add(_isConnected);
    log('🌐 Connectivity status: ${_isConnected ? 'Online' : 'Offline'}');
  }

  void dispose() {
    _connectivityController.close();
  }
}
