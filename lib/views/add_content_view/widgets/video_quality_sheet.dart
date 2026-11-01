import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_video_editor/pro_video_editor.dart' as pve;

import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/modal_sheet_container.dart';

class _VideoQuality {
  const _VideoQuality(this.label, this.bitrate);
  final String label;
  final int bitrate;
}

// ponytail: absolute fallback range, only used before metadata loads or when
// duration/size can't yield a real bitrate.
const _fallbackMaxBitrate = 8000000;

String _formatSize(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).round()} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

void showVideoQualitySheet(
  BuildContext context, {
  required File source,
  required void Function(File compressed) onCompressed,
}) {
  showAppModalSheet(
    context: context,
    builder: (_) => VideoQualitySheet(
      source: source,
      onCompressed: onCompressed,
    ),
  );
}

class VideoQualitySheet extends HookWidget {
  const VideoQualitySheet({
    super.key,
    required this.source,
    required this.onCompressed,
  });

  final File source;
  final void Function(File compressed) onCompressed;

  @override
  Widget build(BuildContext context) {
    final metadata = useState<pve.VideoMetadata?>(null);
    final processingBitrate = useState<int?>(null);
    final customBitrateOverride = useState<int?>(null);

    useEffect(() {
      pve.ProVideoEditor.instance
          .getMetadata(pve.EditorVideo.file(source.path))
          .then((m) {
        if (context.mounted) {
          metadata.value = m;
        }
      });
      return null;
    }, [source.path]);

    Future<void> compress(int bitrate) async {
      if (processingBitrate.value != null) {
        return;
      }
      processingBitrate.value = bitrate;

      try {
        final dir = await getTemporaryDirectory();
        final output =
            '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.mp4';

        final path = await pve.ProVideoEditor.instance.renderVideoToFile(
          output,
          pve.VideoRenderData(
            videoSegments: [
              pve.VideoSegment(video: pve.EditorVideo.file(source.path)),
            ],
            bitrate: bitrate,
            maxFrameRate: 30,
            shouldOptimizeForNetworkUse: true,
          ),
        );

        final compressed = File(path);
        if (!compressed.existsSync()) {
          throw Exception('empty output');
        }

        if (!context.mounted) {
          return;
        }
        Navigator.pop(context);
        onCompressed(compressed);
      } catch (e) {
        if (context.mounted) {
          BotToastUtils.showError(context.t.errorUploadingMedia);
        }
      } finally {
        processingBitrate.value = null;
      }
    }

    final duration = metadata.value?.duration;
    final originalSize = metadata.value?.fileSize ?? source.lengthSync();

    // The real bitrate the source was recorded at — compressed output can
    // never sound/look "better" than this, so every option is capped by it.
    final originalBitrate = (duration != null && duration.inMilliseconds > 0)
        ? (originalSize * 8000 / duration.inMilliseconds).round()
        : null;

    final maxBitrate = originalBitrate ?? _fallbackMaxBitrate;
    final minBitrate = (maxBitrate * 0.2).round().clamp(1, maxBitrate);

    final qualities = [
      _VideoQuality(
        'Medium',
        (maxBitrate * 0.6).round().clamp(minBitrate, maxBitrate),
      ),
      _VideoQuality(
        'Low',
        (maxBitrate * 0.35).round().clamp(minBitrate, maxBitrate),
      ),
    ];

    final defaultCustomBitrate =
        (maxBitrate * 0.6).round().clamp(minBitrate, maxBitrate);
    final customBitrate = (customBitrateOverride.value ?? defaultCustomBitrate)
        .clamp(minBitrate, maxBitrate);
    final isProcessingCustom = processingBitrate.value == customBitrate;

    int? estimate(int bitrate) => duration == null
        ? null
        : (bitrate * duration.inMilliseconds / 8000).round();

    return ModalSheetContainer(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(child: ModalBottomSheetHandle()),
              const SizedBox(height: kDefaultPadding / 2),
              Text(
                context.t.videoQuality.capitalizeFirst(),
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: kDefaultPadding / 2),
              for (final quality in qualities) ...[
                _QualityOption(
                  label: quality.label,
                  estimatedSize: estimate(quality.bitrate),
                  originalSize: originalSize,
                  isProcessing: processingBitrate.value == quality.bitrate,
                  enabled: processingBitrate.value == null,
                  onTap: () => compress(quality.bitrate),
                ),
                const SizedBox(height: kDefaultPadding / 4),
              ],
              const SizedBox(height: kDefaultPadding / 4),
              _CustomQualitySlider(
                bitrate: customBitrate,
                minBitrate: minBitrate,
                maxBitrate: maxBitrate,
                estimatedSize: estimate(customBitrate),
                originalSize: originalSize,
                isProcessing: isProcessingCustom,
                enabled: processingBitrate.value == null,
                onChanged: (value) => customBitrateOverride.value = value,
                onApply: () => compress(customBitrate),
              ),
              SizedBox(height: kDefaultPadding + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.label,
    required this.estimatedSize,
    required this.originalSize,
    required this.isProcessing,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final int? estimatedSize;
  final int originalSize;
  final bool isProcessing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  if (estimatedSize != null)
                    Text(
                      '~${_formatSize(estimatedSize!)} '
                      '(${context.t.originalMedia} ${_formatSize(originalSize)})',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            if (isProcessing)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomQualitySlider extends StatelessWidget {
  const _CustomQualitySlider({
    required this.bitrate,
    required this.minBitrate,
    required this.maxBitrate,
    required this.estimatedSize,
    required this.originalSize,
    required this.isProcessing,
    required this.enabled,
    required this.onChanged,
    required this.onApply,
  });

  final int bitrate;
  final int minBitrate;
  final int maxBitrate;
  final int? estimatedSize;
  final int originalSize;
  final bool isProcessing;
  final bool enabled;
  final ValueChanged<int> onChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final range = maxBitrate - minBitrate;
    final percent =
        range == 0 ? 100 : ((bitrate - minBitrate) / range * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Custom · $percent%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (estimatedSize != null)
                Text(
                  '~${_formatSize(estimatedSize!)} '
                  '(${context.t.originalMedia} ${_formatSize(originalSize)})',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              overlayShape: SliderComponentShape.noOverlay,
              inactiveTickMarkColor: kTransparent,
              activeTickMarkColor: kTransparent,
            ),
            child: Slider(
              value: bitrate.toDouble(),
              min: minBitrate.toDouble(),
              max: range == 0 ? minBitrate.toDouble() + 1 : maxBitrate.toDouble(),
              divisions: range == 0 ? null : 20,
              activeColor: Theme.of(context).primaryColor,
              thumbColor: Theme.of(context).primaryColor,
              onChanged: enabled && range != 0
                  ? (value) => onChanged(value.round())
                  : null,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: enabled ? onApply : null,
              child: isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Compress'),
            ),
          ),
        ],
      ),
    );
  }
}
