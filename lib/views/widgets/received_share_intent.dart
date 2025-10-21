import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:share_handler/share_handler.dart';

import '../../common/common_regex.dart';
import '../../common/media_handler/media_handler.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import 'dotted_container.dart';
import 'link_previewer.dart';
import 'no_content_widgets.dart';
import 'parsed_media_container.dart';

class ReceivedShareIntent extends StatelessWidget {
  const ReceivedShareIntent({super.key, required this.media});

  final SharedMedia media;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: !canSign()
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                VerticalViewModeWidget(),
              ],
            )
          : _buildView(context),
    );
  }

  Widget _buildView(BuildContext context) {
    return Builder(builder: (context) {
      final content = media.content;

      final attachements = media.attachments;
      final selectedAttachement =
          attachements != null && attachements.isNotEmpty
              ? attachements.first
              : null;

      SharedAttachmentType? type;

      if (selectedAttachement != null) {
        if (selectedAttachement.type == SharedAttachmentType.image) {
          type = selectedAttachement.type;
        }

        if (selectedAttachement.type == SharedAttachmentType.video) {
          type = selectedAttachement.type;
        }

        if (selectedAttachement.type == SharedAttachmentType.file) {
          final extension = selectedAttachement.path.split('.').last;

          if (isImageExtension(extension)) {
            type = SharedAttachmentType.image;
          } else if (isVideoExtension(extension)) {
            type = SharedAttachmentType.video;
          }
        }
      }

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalBottomSheetHandle(),
            if (type == null && content == null)
              Text(context.t.invalidInvoice)
            else ...[
              Text(
                context.t.shareContent,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              if (type != null)
                _media(selectedAttachement, type)
              else if (content != null)
                urlRegExp.hasMatch(content)
                    ? UrlPreviewContainer(url: content)
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: kDefaultPadding / 2,
                        ),
                        child: Text('"${content.trim()}"'),
                      ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              _addToNote(type, selectedAttachement, context, content),
            ],
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      );
    });
  }

  SizedBox _addToNote(
      SharedAttachmentType? type,
      SharedAttachment? selectedAttachement,
      BuildContext context,
      String? content) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          String text;
          if (type != null) {
            final media = File(selectedAttachement!.path);
            final mediaUrl = await MediaHandler.uploadMedia(media);

            if (mediaUrl == null) {
              if (context.mounted) {
                BotToastUtils.showError(context.t.errorUploadingMedia);
              }

              return;
            }

            text = mediaUrl;
          } else {
            text = content!;
          }

          if (context.mounted) {
            YNavigator.pop(context);
            YNavigator.pushPage(
              context,
              (context) => AddContentView(
                content: text,
                contentType: AppContentType.note,
              ),
            );
          }
        },
        child: Text(context.t.addToNotes),
      ),
    );
  }

  Builder _media(
      SharedAttachment? selectedAttachement, SharedAttachmentType? type) {
    return Builder(
      builder: (context) {
        if (selectedAttachement != null) {
          if (type == SharedAttachmentType.image) {
            return _image(selectedAttachement);
          }

          if (type == SharedAttachmentType.video) {
            return _video(selectedAttachement);
          }
        }

        return const SizedBox();
      },
    );
  }

  Widget _video(SharedAttachment selectedAttachement) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: RegularVideoPlayer(
        link: selectedAttachement.path,
        isNetwork: false,
      ),
    );
  }

  Widget _image(SharedAttachment selectedAttachement) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ExtendedImage.file(
        File(selectedAttachement.path),
        fit: BoxFit.cover,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
      ),
    );
  }
}
