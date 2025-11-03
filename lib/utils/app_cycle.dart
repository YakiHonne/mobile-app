import 'dart:async';

import 'package:flutter/material.dart';

import '../common/notifications/notification_helper.dart';
import '../models/app_models/diverse_functions.dart';
import 'utils.dart';

class YakihonneCycle with WidgetsBindingObserver {
  YakihonneCycle({required this.buildContext}) {
    WidgetsBinding.instance.addObserver(this);
  }
  Timer? timer;
  BuildContext buildContext;
  late AppLifecycleState _state;
  AppLifecycleState get state => _state;
  bool _hasGoneOffline = false;

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        {
          if (_hasGoneOffline) {
            reset();
            _hasGoneOffline = false;

            break;
          }
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        {
          if (!_hasGoneOffline) {
            if (canSign()) {
              NotificationHelper.sharedInstance.setOffline();
              notificationsCubit.closeNotifications();
            }

            _hasGoneOffline = true;
          }
          break;
        }
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
    }
  }
}

Future<void> reset() async {
  await nc.forceReconnect();

  if (canSign()) {
    notificationsCubit.initNotifications();
    connectivityService.checkInternet();
    walletManagerCubit.processUnprocessedInvoices();
  }
}

class AppLifecycleNotifier {
  AppLifecycleNotifier() {
    WidgetsBinding.instance.addObserver(AppLifecycleObserver(this));
  }
  final _lifecycleController = StreamController<AppLifecycleState>.broadcast();

  Stream<AppLifecycleState> get lifecycleStream => _lifecycleController.stream;

  void dispose() {
    WidgetsBinding.instance.removeObserver(AppLifecycleObserver(this));
    _lifecycleController.close();
  }
}

class AppLifecycleObserver extends WidgetsBindingObserver {
  AppLifecycleObserver(this._appLifecycleNotifier);
  final AppLifecycleNotifier _appLifecycleNotifier;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleNotifier._lifecycleController.add(state);
  }
}
