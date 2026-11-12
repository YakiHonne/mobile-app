import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

/// Reports device interface availability and the user's relay socket status.
class DesktopConnectionStatus extends StatefulWidget {
  const DesktopConnectionStatus({super.key, required this.compact});

  final bool compact;

  @override
  State<DesktopConnectionStatus> createState() =>
      _DesktopConnectionStatusState();
}

class _DesktopConnectionStatusState extends State<DesktopConnectionStatus> {
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = connectivityService.onStatusChanged.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
    nc.addConnectStatusListener(_relayChanged);
  }

  void _relayChanged(String relay, int status) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    nc.removeConnectStatusListener(_relayChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final network = !connectivityService.hasKnownConnection
        ? context.t.unknown
        : connectivityService.isConnected
            ? context.t.desktopInterfaceAvailable
            : context.t.offline;
    final relays = currentUserRelayList.urls.toSet();
    final connected = relays
        .where((relay) =>
            nc.connectStatus[relay] == 1 && nc.isWebSocketOpen(relay))
        .length;
    final label = '${context.t.desktopNetworkInterface}: $network · '
        '${context.t.desktopRelayConnections}: '
        '$connected/${relays.length}';
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 4),
          child: widget.compact
              ? Icon(Icons.hub_outlined, color: Theme.of(context).hintColor)
              : Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );
  }
}
