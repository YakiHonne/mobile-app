// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../../common/media_handler/media_handler.dart';
import '../../../logic/blossom_cubit/blossom_cubit.dart';
import '../../../utils/utils.dart';

class BlossomMediaUploader extends HookWidget {
  const BlossomMediaUploader({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedFile = useState<File?>(null);
    final selectedServers = useState<List<String>>([]);
    final blossomCubit = context.read<BlossomCubit>();
    final servers = blossomCubit.blossomServers;

    useEffect(() {
      selectedServers.value = List.from(servers);
      return null;
    }, [servers]);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kDefaultPadding),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: kDefaultPadding),
            _buildDropZone(context, selectedFile),
            const SizedBox(height: kDefaultPadding),
            _buildServersList(context, servers, selectedServers),
            const SizedBox(height: kDefaultPadding),
            _buildUploadButton(
              context,
              selectedFile.value,
              selectedServers.value,
            ),
            const SizedBox(height: kDefaultPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(
      BuildContext context, ValueNotifier<File?> selectedFile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: GestureDetector(
        onTap: () => _pickFile(context, selectedFile),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CustomPaint(
              painter: _DashedRectPainter(
                color: Theme.of(context).dividerColor,
                strokeWidth: 1.5,
                gap: 5,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(kDefaultPadding * 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding),
                ),
                child: selectedFile.value != null
                    ? _buildMediaPreview(context, selectedFile.value!)
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(kDefaultPadding / 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SvgPicture.asset(
                              FeatureIcons.media,
                              width: 40,
                              height: 40,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).primaryColorDark,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: kDefaultPadding),
                          Text(
                            context.t.media,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.t.pickYourMedia,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: Theme.of(context).highlightColor,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
            if (selectedFile.value != null)
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  onTap: () => selectedFile.value = null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      FeatureIcons.closeRaw,
                      colorFilter: const ColorFilter.mode(
                        kWhite,
                        BlendMode.srcIn,
                      ),
                      width: 16,
                      height: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, File file) {
    final isVideo = _isVideoFile(file.path);

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).cardColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideo
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          FeatureIcons.video,
                          width: 40,
                          height: 40,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).hintColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.t.videoSelected,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  )
                : Image.file(
                    file,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        Text(
          file.path.split('/').last,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  bool _isVideoFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  Widget _buildServersList(
    BuildContext context,
    List<String> servers,
    ValueNotifier<List<String>> selectedServers,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.servers,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: servers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final server = servers[index];
                final isSelected = selectedServers.value.contains(server);

                return InkWell(
                  onTap: () {
                    final current = List<String>.from(selectedServers.value);
                    if (isSelected) {
                      current.remove(server);
                    } else {
                      current.add(server);
                    }
                    selectedServers.value = current;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kDefaultPadding,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              final current =
                                  List<String>.from(selectedServers.value);
                              if (val ?? false) {
                                current.add(server);
                              } else {
                                current.remove(server);
                              }
                              selectedServers.value = current;
                            },
                            activeColor: kMainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            server,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(
    BuildContext context,
    File? file,
    List<String> selectedServers,
  ) {
    final canUpload = file != null && selectedServers.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: TextButton(
        onPressed: canUpload
            ? () async {
                final bytes = await file.readAsBytes();
                final mimeType = _getMimeType(file.path);
                if (context.mounted) {
                  await context.read<BlossomCubit>().uploadMedia(
                        fileBytes: bytes,
                        filePath: file.path,
                        mimeType: mimeType,
                        targetServers: selectedServers,
                      );
                  Navigator.pop(context);
                }
              }
            : null,
        style: TextButton.styleFrom(
          backgroundColor: canUpload
              ? Theme.of(context).cardColor
              : Theme.of(context).disabledColor,
          foregroundColor: canUpload
              ? Theme.of(context).primaryColorDark
              : Theme.of(context).highlightColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: canUpload
                  ? Theme.of(context).dividerColor
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
        ),
        child: Text(
          context.t.upload.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _pickFile(
      BuildContext context, ValueNotifier<File?> selectedFile) async {
    final file = await MediaHandler.selectMedia(MediaType.gallery);
    if (file != null) {
      selectedFile.value = file;
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
  });
  final Color color;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(kDefaultPadding),
      ));

    canvas.drawPath(
      dashPath(
        path,
        dashArray: CircularIntervalList<double>([gap, gap]),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_DashedRectPainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gap != oldDelegate.gap;
}
