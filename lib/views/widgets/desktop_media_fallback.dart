import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/utils.dart';

bool supportsEmbeddedDesktopMedia(TargetPlatform platform) =>
    platform != TargetPlatform.windows && platform != TargetPlatform.linux;

/// Keeps unsupported desktop playback actionable without starting a plugin.
class DesktopMediaFallback extends StatelessWidget {
  const DesktopMediaFallback({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final canOpen =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    return ColoredBox(
      color: Theme.of(context).cardColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.t.desktopPlaybackUnavailable,
                  textAlign: TextAlign.center),
              if (canOpen)
                TextButton(
                  onPressed: () => launchUrlString(
                    url,
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(context.t.enableExternalBrowser),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
