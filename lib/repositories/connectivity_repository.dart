// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Repository for managing network connectivity state and monitoring changes
class ConnectivityRepository {
  ConnectivityRepository({
    String testHost = _defaultTestHost,
    Connectivity? connectivity,
    Future<List<InternetAddress>> Function(String host)? lookup,
  })  : _lookup = lookup ?? InternetAddress.lookup,
        _testHost = testHost,
        _connectivity = connectivity ?? Connectivity() {
    _initializeConnectivityListener();
    unawaited(checkConnectionEnabled());
  }

  // ==================================================
  // CONSTANTS
  // ==================================================

  static const String _defaultTestHost = 'google.com';
  static const Duration _internetCheckTimeout = Duration(seconds: 10);

  // ==================================================
  // PRIVATE FIELDS
  // ==================================================

  final Connectivity _connectivity;
  final Future<List<InternetAddress>> Function(String host) _lookup;
  final String _testHost;
  final StreamController<bool> _connectionChangeController =
      StreamController.broadcast();
  final StreamController<void> _statusChangeController =
      StreamController.broadcast();

  bool _hasConnection = false;
  bool _hasKnownConnection = false;
  int _changeGeneration = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // ==================================================
  // PUBLIC GETTERS
  // ==================================================

  /// Current connection status
  bool get hasConnection => _hasConnection;

  /// Whether an interface result has been received from the platform.
  bool get hasKnownConnection => _hasKnownConnection;

  /// Stream of connectivity changes
  Stream<bool> get connectivityChangeStream =>
      _connectionChangeController.stream;

  Stream<void> get statusChangeStream => _statusChangeController.stream;

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
    final generation = ++_changeGeneration;
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      final isConnected = _isValidConnection(connectivityResults);
      if (generation == _changeGeneration) {
        _setConnectionStatus(isConnected);
      }
      return _hasConnection;
    } catch (e) {
      // A plugin failure does not establish that the device is offline.
      if (generation == _changeGeneration) {
        _markUnknown();
      }
      return _hasConnection;
    }
  }

  /// Performs actual internet connectivity test by reaching external host
  Future<bool> checkInternetConnection() async {
    try {
      final result = await _lookup(_testHost).timeout(_internetCheckTimeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ==================================================
  // PRIVATE HELPER METHODS
  // ==================================================

  /// Handles connectivity changes from the stream
  void _onConnectivityChanged(List<ConnectivityResult> connectivityResults) {
    final isConnected = _isValidConnection(connectivityResults);
    _changeGeneration++;
    _setConnectionStatus(isConnected);
  }

  /// Handles errors in connectivity stream
  void _onConnectivityError(Object error) {
    // A stream error is not evidence that the device is offline.
    _changeGeneration++;
    _markUnknown();
  }

  /// Determines if connectivity results indicate a valid connection
  bool _isValidConnection(List<ConnectivityResult> results) {
    return results.any((result) => result.isConnected);
  }

  void _markUnknown() {
    if (_hasKnownConnection) {
      _hasKnownConnection = false;
      if (!_statusChangeController.isClosed) {
        _statusChangeController.add(null);
      }
    }
  }

  void _setConnectionStatus(bool isConnected) {
    if (_hasKnownConnection && _hasConnection == isConnected) {
      return;
    }
    final changed = _hasConnection != isConnected;
    _hasConnection = isConnected;
    _hasKnownConnection = true;
    if (!_statusChangeController.isClosed) {
      _statusChangeController.add(null);
    }
    if (changed && !_connectionChangeController.isClosed) {
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
    await _statusChangeController.close();
  }
}

// ==================================================
// EXTENSION FOR CONNECTIVITY RESULT
// ==================================================

/// Extension to add utility methods to ConnectivityResult
extension ConnectivityResultExtension on ConnectivityResult {
  /// Returns true if this result represents an active connection
  bool get isConnected {
    return this != ConnectivityResult.none;
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

  /// Refresh interface availability periodically in case an event is missed.
  void startPeriodicChecks({Duration interval = const Duration(minutes: 1)}) {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(interval, (_) {
      _repository.checkConnectionEnabled();
    });
  }

  /// Stop periodic checks
  void stopPeriodicChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  /// Get current connection status
  bool get isConnected => _repository.hasConnection;

  bool get hasKnownConnection => _repository.hasKnownConnection;

  /// Get connectivity change stream
  Stream<bool> get onConnectivityChanged =>
      _repository.connectivityChangeStream;

  Stream<void> get onStatusChanged => _repository.statusChangeStream;

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
