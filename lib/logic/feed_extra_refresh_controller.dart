import 'dart:async';

class FeedExtraRefreshController {
  FeedExtraRefreshController({
    required Future<void> Function() onRefresh,
    this.interval = const Duration(seconds: 30),
    this.resumeDelay = const Duration(seconds: 3),
  }) : _onRefresh = onRefresh;

  final Future<void> Function() _onRefresh;
  final Duration interval;
  final Duration resumeDelay;

  Timer? _periodicTimer;
  Timer? _resumeTimer;
  bool _feedActive = false;
  bool _appResumed = true;
  bool _hasContent = false;
  bool _requestInFlight = false;
  bool _refreshQueued = false;
  bool _disposed = false;

  bool get _canRefresh =>
      !_disposed && _feedActive && _appResumed && _hasContent;

  void setFeedActive(bool active) {
    if (_feedActive == active) {
      return;
    }
    _feedActive = active;
    if (active) {
      _startPeriodicTimer();
      // Lazy feeds only poll immediately on re-entry after their first page
      // has loaded and enabled refresh through setHasContent(true).
      if (_canRefresh && _resumeTimer == null) {
        unawaited(_runRefresh(queueIfInFlight: true));
      }
    } else {
      _refreshQueued = false;
      _cancelTimers();
    }
  }

  void setAppResumed(bool resumed) {
    if (_appResumed == resumed) {
      return;
    }
    _appResumed = resumed;
    if (!resumed) {
      _refreshQueued = false;
      _cancelTimers();
    } else if (_canRefresh) {
      _scheduleResumePoll();
    }
  }

  void setHasContent(bool hasContent) {
    if (_hasContent == hasContent) {
      return;
    }
    _hasContent = hasContent;
    if (hasContent) {
      _startPeriodicTimer();
    } else {
      _refreshQueued = false;
      _cancelTimers();
    }
  }

  void reset() {
    _cancelTimers();
    _startPeriodicTimer();
  }

  void dispose() {
    _disposed = true;
    _refreshQueued = false;
    _cancelTimers();
  }

  void _startPeriodicTimer() {
    if (!_canRefresh || _periodicTimer != null || _resumeTimer != null) {
      return;
    }
    _periodicTimer = Timer.periodic(interval, (_) {
      unawaited(_runRefresh());
    });
  }

  void _scheduleResumePoll() {
    if (!_canRefresh) {
      return;
    }
    _cancelTimers();
    _resumeTimer = Timer(resumeDelay, () {
      _resumeTimer = null;
      if (!_canRefresh) {
        return;
      }
      unawaited(_refreshThenStartPeriodicTimer());
    });
  }

  Future<void> _refreshThenStartPeriodicTimer() async {
    try {
      await _runRefresh(queueIfInFlight: true);
    } finally {
      _startPeriodicTimer();
    }
  }

  Future<void> _runRefresh({bool queueIfInFlight = false}) async {
    if (!_canRefresh) {
      return;
    }
    if (_requestInFlight) {
      if (queueIfInFlight) {
        _refreshQueued = true;
      }
      return;
    }

    _requestInFlight = true;
    try {
      await _onRefresh();
    } finally {
      _requestInFlight = false;
      if (_refreshQueued) {
        _refreshQueued = false;
        if (_canRefresh) {
          unawaited(_runRefresh());
        }
      }
    }
  }

  void _cancelTimers() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _resumeTimer?.cancel();
    _resumeTimer = null;
  }
}
