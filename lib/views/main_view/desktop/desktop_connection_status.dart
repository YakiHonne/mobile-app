import 'dart:async';

import 'package:flutter/material.dart';

import '../../../utils/utils.dart';

String _networkStatus(BuildContext context) =>
    !connectivityService.hasKnownConnection
        ? context.t.unknown
        : connectivityService.isConnected
            ? context.t.desktopInterfaceAvailable
            : context.t.offline;

bool _relayIsOpen(String relay) =>
    nc.connectStatus[relay] == 1 && nc.isWebSocketOpen(relay);

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
    final network = _networkStatus(context);
    final relays = currentUserRelayList.urls.toSet();
    final connected = relays.where(_relayIsOpen).length;
    final label = '${context.t.desktopNetworkInterface}: $network · '
        '${context.t.desktopRelayConnections}: '
        '$connected/${relays.length}';
    final theme = Theme.of(context);
    final icon = Icon(Icons.public, color: theme.primaryColorDark, size: 22);
    return Tooltip(
      message: label,
      child: Semantics(
        label: widget.compact ? label : context.t.network,
        button: true,
        excludeSemantics: true,
        child: Center(
          child: Material(
            color: kTransparent,
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const _ConnectionDetailsDialog(),
              ),
              borderRadius: BorderRadius.circular(kDefaultPadding),
              child: Container(
                width: widget.compact ? 43 : double.infinity,
                height: 43,
                padding: widget.compact
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                decoration: BoxDecoration(
                  color: theme.cardColor.withValues(alpha: 0.55),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                  shape: widget.compact ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.compact
                      ? null
                      : BorderRadius.circular(kDefaultPadding),
                ),
                child: widget.compact
                    ? Center(child: icon)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          icon,
                          const SizedBox(width: kDefaultPadding / 1.5),
                          Flexible(
                            child: Text(
                              context.t.network,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionDetailsDialog extends StatefulWidget {
  const _ConnectionDetailsDialog();

  @override
  State<_ConnectionDetailsDialog> createState() =>
      _ConnectionDetailsDialogState();
}

class _ConnectionDetailsDialogState extends State<_ConnectionDetailsDialog> {
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
    final theme = Theme.of(context);
    final relays = currentUserRelayList.urls.toSet().toList()..sort();
    final connected = relays.where(_relayIsOpen).length;
    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding * 1.5),
        side: BorderSide(color: theme.dividerColor, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: Text(context.t.desktopConnectionDetails,
                      style: theme.textTheme.titleLarge),
                ),
                IconButton(
                  tooltip: context.t.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ]),
              const SizedBox(height: kDefaultPadding / 2),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(context.t.desktopConnectionExplanation,
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: kDefaultPadding),
                      _StatusRow(
                        label: context.t.desktopNetworkInterface,
                        value: _networkStatus(context),
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      _StatusRow(
                        label: context.t.desktopRelayConnections,
                        value: '$connected/${relays.length}',
                      ),
                      const SizedBox(height: kDefaultPadding / 2),
                      if (relays.isEmpty)
                        Text(context.t.noRelays,
                            style: theme.textTheme.bodySmall)
                      else
                        ...relays.map((relay) {
                          final open = _relayIsOpen(relay);
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              open
                                  ? Icons.check_circle_outline
                                  : Icons.link_off,
                              color: open ? kGreen : theme.hintColor,
                            ),
                            title:
                                Text(relay, style: theme.textTheme.bodySmall),
                            subtitle: Text(
                              open
                                  ? context.t.desktopSocketOpen
                                  : context.t.desktopSocketClosed,
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: kDefaultPadding / 2),
        Flexible(
          child: Text(value, textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}
