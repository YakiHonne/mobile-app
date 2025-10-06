// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Repository for managing network connectivity state and monitoring changes
class ConnectivityRepository {
  ConnectivityRepository({
    String testHost = _defaultTestHost,
  }) : _testHost = testHost {
    _initializeConnectivityListener();
  }

  // ==================================================
  // CONSTANTS
  // ==================================================

  static const String _defaultTestHost = 'google.com';
  static const Duration _internetCheckTimeout = Duration(seconds: 10);

  // ==================================================
  // PRIVATE FIELDS
  // ==================================================

  final Connectivity _connectivity = Connectivity();
  final String _testHost;
  final StreamController<bool> _connectionChangeController =
      StreamController.broadcast();

  bool _hasConnection = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // ==================================================
  // PUBLIC GETTERS
  // ==================================================

  /// Current connection status
  bool get hasConnection => _hasConnection;

  /// Stream of connectivity changes
  Stream<bool> get connectivityChangeStream =>
      _connectionChangeController.stream;

  // ==================================================
  // INITIALIZATION
  // ==================================================

  /// Sets up the connectivity listener
  void _initializeConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: _onConnectivityError,
    );
  }

  // ==================================================
  // CONNECTIVITY METHODS
  // ==================================================

  /// Checks if device has network connectivity (WiFi or Mobile)
  Future<bool> checkConnectionEnabled() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final isConnected = _isValidConnection(connectivityResults);
      _updateConnectionStatus(isConnected);
      return isConnected;
    } catch (e) {
      _updateConnectionStatus(false);
      return false;
    }
  }

  /// Performs actual internet connectivity test by reaching external host
  Future<bool> checkInternetConnection() async {
    final previousConnection = _hasConnection;

    try {
      final result = await InternetAddress.lookup(_testHost)
          .timeout(_internetCheckTimeout);

      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectionStatus(isConnected);

      // Only notify if connection status changed
      if (previousConnection != isConnected) {
        _notifyConnectionChange(isConnected);
      }

      return isConnected;
    } on SocketException {
      _updateConnectionStatus(false);
      if (previousConnection) {
        _notifyConnectionChange(false);
      }
      return false;
    } on TimeoutException {
      _updateConnectionStatus(false);
      if (previousConnection) {
        _notifyConnectionChange(false);
      }
      return false;
    } catch (e) {
      _updateConnectionStatus(false);
      if (previousConnection) {
        _notifyConnectionChange(false);
      }
      return false;
    }
  }

  // ==================================================
  // PRIVATE HELPER METHODS
  // ==================================================

  /// Handles connectivity changes from the stream
  void _onConnectivityChanged(List<ConnectivityResult> connectivityResults) {
    final isConnected = _isValidConnection(connectivityResults);
    _updateConnectionStatus(isConnected);
    _notifyConnectionChange(isConnected);
  }

  /// Handles errors in connectivity stream
  void _onConnectivityError(Object error) {
    // Log error if logging is available
    // logger?.error('Connectivity stream error: $error');
    _updateConnectionStatus(false);
    _notifyConnectionChange(false);
  }

  /// Determines if connectivity results indicate a valid connection
  bool _isValidConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }

    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);
  }

  /// Updates internal connection status
  void _updateConnectionStatus(bool isConnected) {
    _hasConnection = isConnected;
  }

  /// Notifies listeners of connection change
  void _notifyConnectionChange(bool isConnected) {
    if (!_connectionChangeController.isClosed) {
      _connectionChangeController.add(isConnected);
    }
  }

  // ==================================================
  // LIFECYCLE MANAGEMENT
  // ==================================================

  /// Disposes resources and closes streams
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _connectionChangeController.close();
  }
}

// ==================================================
// EXTENSION FOR CONNECTIVITY RESULT
// ==================================================

/// Extension to add utility methods to ConnectivityResult
extension ConnectivityResultExtension on ConnectivityResult {
  /// Returns true if this result represents an active connection
  bool get isConnected {
    return this == ConnectivityResult.mobile ||
        this == ConnectivityResult.wifi ||
        this == ConnectivityResult.ethernet;
  }

  /// Returns a human-readable description of the connection type
  String get displayName {
    switch (this) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }
}

// ==================================================
// CONNECTIVITY REPOSITORY FACTORY
// ==================================================

/// Factory class for creating ConnectivityRepository instances
class ConnectivityRepositoryFactory {
  /// Creates a standard connectivity repository
  static ConnectivityRepository create() {
    return ConnectivityRepository();
  }

  /// Creates a connectivity repository with custom test host
  static ConnectivityRepository createWithCustomHost(String testHost) {
    return ConnectivityRepository(testHost: testHost);
  }

  /// Creates a connectivity repository for testing
  static ConnectivityRepository createForTesting({
    String testHost = 'example.com',
  }) {
    return ConnectivityRepository(testHost: testHost);
  }
}

// ==================================================
// CONNECTIVITY SERVICE (OPTIONAL WRAPPER)
// ==================================================

/// High-level service that wraps ConnectivityRepository with additional features
class ConnectivityService {
  ConnectivityService({ConnectivityRepository? repository})
      : _repository = repository ?? ConnectivityRepository();

  final ConnectivityRepository _repository;
  Timer? _periodicCheckTimer;

  /// Start periodic internet checks
  void startPeriodicChecks({Duration interval = const Duration(minutes: 1)}) {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(interval, (_) {
      _repository.checkInternetConnection();
    });
  }

  /// Stop periodic checks
  void stopPeriodicChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  /// Get current connection status
  bool get isConnected => _repository.hasConnection;

  /// Get connectivity change stream
  Stream<bool> get onConnectivityChanged =>
      _repository.connectivityChangeStream;

  /// Check connection status
  Future<bool> checkConnection() => _repository.checkConnectionEnabled();

  /// Check internet connectivity
  Future<bool> checkInternet() => _repository.checkInternetConnection();

  /// Dispose resources
  Future<void> dispose() async {
    stopPeriodicChecks();
    await _repository.dispose();
  }
}
