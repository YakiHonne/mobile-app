import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import 'profile_share_view.dart';

class FlipToShareWrapper extends StatefulWidget {
  const FlipToShareWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<FlipToShareWrapper> createState() => _FlipToShareWrapperState();
}

class _FlipToShareWrapperState extends State<FlipToShareWrapper>
    with WidgetsBindingObserver {
  StreamSubscription<AccelerometerEvent>? _sub;
  OverlayEntry? _overlayEntry;
  bool _isShowing = false;
  Timer? _debounce;

  // EMA-smoothed current Y reading.
  double? _smoothY;

  // Phone must carry at least this much gravity on the Y axis (i.e. not
  // tilted diagonally) before we consider it upright or flipped.
  static const double _yMin = 7.0;
  // If Z carries most of gravity the phone is lying flat — ignore.
  static const double _zFlatMax = 6.0;
  static const Duration _holdDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(_onAccelerometer);
  }

  void _onAccelerometer(AccelerometerEvent e) {
    // Ignore when the phone is flat on a surface.
    if (e.z.abs() > _zFlatMax) {
      _debounce?.cancel();
      _debounce = null;
      return;
    }

    // Low-pass filter: smooth out sensor jitter.
    _smoothY = _smoothY == null ? e.y : _smoothY! * 0.25 + e.y * 0.75;
    final sy = _smoothY!;

    // Ignore weak/diagonal signals.
    if (sy.abs() < _yMin) {
      _debounce?.cancel();
      _debounce = null;
      return;
    }

    // Absolute-orientation flip: upright holds gravity at +Y (~+9.8), a full
    // 180° table-flip inverts it to -Y (~-9.8). No baseline to drift.
    final flipped = sy < -_yMin;

    if (flipped && !_isShowing) {
      // Arm a timer — phone must stay flipped for the full hold duration.
      _debounce ??= Timer(_holdDuration, _show);
    } else if (!flipped && _isShowing) {
      // Phone righted: dismiss immediately.
      _debounce?.cancel();
      _debounce = null;
      _hide();
    } else if (!flipped) {
      // Flipped but we're already showing, or not flipped — clear any pending.
      _debounce?.cancel();
      _debounce = null;
    }
  }

  void _show() {
    _debounce = null;
    if (_isShowing || !mounted) {
      return;
    }
    if (!canSign()) {
      return;
    }
    final metadata = nostrRepository.currentMetadata;
    if (metadata.pubkey.isEmpty) {
      return;
    }

    HapticFeedback.mediumImpact();
    _isShowing = true;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: Transform.rotate(
          // Rotate 180° so the person facing the phone sees it right-side up.
          angle: math.pi,
          child: Material(
            color: Colors.transparent,
            child: ProfileShareView(
              metadata: metadata,
              onClose: _hide,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hide() {
    if (!_isShowing) {
      return;
    }
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
    _isShowing = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sub?.pause();
      _debounce?.cancel();
      _debounce = null;
      _hide();
    } else if (state == AppLifecycleState.resumed) {
      if (_sub?.isPaused ?? false) {
        _sub?.resume();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _debounce?.cancel();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
