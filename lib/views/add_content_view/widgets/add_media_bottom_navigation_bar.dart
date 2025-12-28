import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:image_editor_plus/options.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';
import 'package:nostr_core_enhanced/utils/string_utils.dart';

import '../../../common/media_handler/media_handler.dart';
import '../../../logic/add_media_cubit/add_media_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/single_image_selector.dart';
import '../../write_note_view/widgets/mention_text_field.dart';
import '../../write_note_view/widgets/publish_media_container.dart';

class AddMediaBottomNavigationBar extends HookWidget {
  const AddMediaBottomNavigationBar({
    super.key,
    required this.media,
    required this.isVideo,
    required this.description,
    required this.thumbnail,
    required this.isSensitive,
    required this.onMediaSelected,
  });

  final ValueNotifier<File?> media;
  final ValueNotifier<bool> isVideo;
  final ValueNotifier<String> description;
  final ValueNotifier<String> thumbnail;
  final ValueNotifier<bool> isSensitive;
  final Function(File, bool) onMediaSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMediaCubit, AddMediaState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom,
            left: kDefaultPadding / 2,
            right: kDefaultPadding / 2,
            top: kDefaultPadding / 2,
          ),
          height: 85,
          child: state.status != PublishMediaStatus.idle
              ? MediaPublishingRow(isVideo: isVideo.value)
              : media.value != null
                  ? MediaOptionsRow(
                      isVideo: isVideo,
                      media: media,
                      onMediaSelected: onMediaSelected,
                      thumbnail: thumbnail,
                      isSensitive: isSensitive,
                      description: description,
                    )
                  : MediaDataRow(
                      isVideo: isVideo,
                      onMediaSelected: onMediaSelected,
                    ),
        );
      },
    );
  }
}

class MediaPublishingRow extends StatelessWidget {
  const MediaPublishingRow({super.key, required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMediaCubit, AddMediaState>(
      builder: (context, state) {
        return Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kDefaultPadding / 4,
                children: [
                  Text(
                    isVideo
                        ? context.t.uploadingVideo
                        : context.t.uploadingImage,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: state.progress),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: Theme.of(context).cardColor,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kDefaultPadding / 4,
                children: [
                  Text(
                    context.t.publishing.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: state.status == PublishMediaStatus.uploading ? 0 : 1,
                    ),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      backgroundColor: Theme.of(context).cardColor,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class MediaOptionsRow extends StatelessWidget {
  const MediaOptionsRow({
    super.key,
    required this.isVideo,
    required this.media,
    required this.onMediaSelected,
    required this.thumbnail,
    required this.isSensitive,
    required this.description,
  });

  final ValueNotifier<bool> isVideo;
  final ValueNotifier<File?> media;
  final Function(File p1, bool p2) onMediaSelected;
  final ValueNotifier<String> thumbnail;
  final ValueNotifier<bool> isSensitive;
  final ValueNotifier<String> description;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            if (!isVideo.value) {
              final editedImage = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageEditor(
                    image: media.value!.readAsBytesSync(),
                    outputFormat: OutputFormat.png,
                  ),
                ),
              );

              if (editedImage != null && editedImage is Uint8List) {
                final file = await saveUint8ListToTempFile(
                  editedImage,
                  '${uuid.v4()}.png',
                );

                onMediaSelected(file, false);
              }
            } else {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) {
                  return SingleImageSelector(
                    onUrlProvided: (url) {
                      thumbnail.value = url;
                      YNavigator.pop(context);
                    },
                    title: gc.t.uploadThumbnail,
                    description: gc.t.chooseThumbnailVideo,
                  );
                },
                backgroundColor: kTransparent,
                useRootNavigator: true,
                elevation: 0,
                useSafeArea: true,
              );
            }
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: 0.5),
              border: Border.all(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            alignment: Alignment.center,
            child: isVideo.value && thumbnail.value.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(1),
                    child: CommonThumbnail(
                      image: thumbnail.value,
                      isRound: true,
                    ),
                  )
                : SvgPicture.asset(
                    isVideo.value
                        ? FeatureIcons.imageAttachment
                        : FeatureIcons.imageFilter,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
        ),
        // Builder(
        //   builder: (context) {
        //     final hasText = description.value.isNotEmpty;

        //     return GestureDetector(
        //       onTap: () {
        //         showModalBottomSheet(
        //           context: context,
        //           elevation: 0,
        //           builder: (_) {
        //             return MediaDescription(description: description);
        //           },
        //           isScrollControlled: true,
        //           useRootNavigator: true,
        //           useSafeArea: true,
        //           backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        //         );
        //       },
        //       child: Container(
        //         width: 45,
        //         height: 45,
        //         decoration: BoxDecoration(
        //           shape: BoxShape.circle,
        //           color: hasText
        //               ? Theme.of(context).primaryColorDark
        //               : Theme.of(context).scaffoldBackgroundColor,
        //           border: Border.all(
        //             color: Theme.of(context).primaryColorDark,
        //           ),
        //         ),
        //         child: Icon(
        //           CupertinoIcons.text_quote,
        //           color: hasText
        //               ? Theme.of(context).scaffoldBackgroundColor
        //               : Theme.of(context).primaryColorDark,
        //           size: 22,
        //         ),
        //       ),
        //     );
        //   },
        // ),
        GestureDetector(
          onTap: () {
            isSensitive.value = !isSensitive.value;
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSensitive.value
                  ? Theme.of(context).primaryColorDark
                  : Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              !isSensitive.value
                  ? FeatureIcons.visible
                  : FeatureIcons.notVisible,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                isSensitive.value
                    ? Theme.of(context).primaryColorLight
                    : Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            media.value = null;
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withValues(alpha: 0.5),
              border: Border.all(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            child: Icon(
              Icons.close,
              color: Theme.of(context).primaryColorDark,
            ),
          ),
        ),
      ],
    );
  }
}

class MediaDescription extends HookWidget {
  const MediaDescription({super.key, required this.description});

  final ValueNotifier<String> description;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(() {
      return MentionTagTextEditingController();
    }, []);

    useMemoized(() {
      controller.setText = description.value;
    }, []);

    final mention = useState<String?>(null);

    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.90,
        minChildSize: 0.40,
        maxChildSize: 0.90,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Center(child: ModalBottomSheetHandle()),
            Text(
              context.t.description.capitalizeFirst(),
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                child: ClipboardPasteMentionTextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    description.value = getRawText(controller);
                  },
                  onMention: (value) async {
                    mention.value = value;
                  },
                  mentionTagDecoration: MentionTagDecoration(
                    maxWords: null,
                    mentionTextStyle: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(color: Theme.of(context).primaryColor),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium!,
                  decoration: InputDecoration(
                    hintText: context.t.writeSomething.capitalizeFirst(),
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    focusColor: Theme.of(context).primaryColorLight,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            MentionBox(
              mention: mention,
              controller: controller,
              onTextChanged: () {},
            ),
            const SizedBox(height: kDefaultPadding),
          ],
        ),
      ),
    );
  }

  String getRawText(MentionTagTextEditingController controller) {
    final text = controller.text;
    final mentions = controller.mentions;

    return text.replaceAllMapped(mentionToken, (match) {
      final removedMention = mentions.removeAt(0);

      if (removedMention is Metadata) {
        return 'nostr:${Nip19.encodePubkey(removedMention.pubkey)}';
      } else {
        return '#$removedMention';
      }
    });
  }
}

class MediaDataRow extends HookWidget {
  const MediaDataRow({
    super.key,
    required this.isVideo,
    required this.onMediaSelected,
  });

  final ValueNotifier<bool> isVideo;
  final Function(File p1, bool p2) onMediaSelected;

  @override
  Widget build(BuildContext context) {
    final types = [
      AppMediaType.image,
      AppMediaType.video,
    ];

    final pageController = usePageController(
      initialPage: isVideo.value ? 1 : 0,
      viewportFraction: 0.3,
    );

    useEffect(() {
      if (pageController.hasClients) {
        final targetPage = isVideo.value ? 1 : 0;
        if ((pageController.page ?? 0).round() != targetPage) {
          pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      }
      return null;
    }, [isVideo.value]);

    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final file = await MediaHandler.selectMedia(
              isVideo.value ? MediaType.video : MediaType.image,
            );

            if (file != null) {
              onMediaSelected(
                file,
                isVideoExtension(
                  file.path.split('.').last,
                ),
              );
            }
          },
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: Theme.of(context).primaryColorDark,
              ),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              FeatureIcons.image,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 35,
            child: PageView.builder(
              controller: pageController,
              itemCount: types.length,
              onPageChanged: (value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    final newValue = (value == 1);
                    if (isVideo.value != newValue) {
                      isVideo.value = newValue;
                    }
                  }
                });
              },
              itemBuilder: (context, index) {
                final type = types[index];

                final isSelected = (index == 1 && isVideo.value) ||
                    (index == 0 && !isVideo.value);

                return GestureDetector(
                  onTap: () {
                    isVideo.value = index == 1;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 40,
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).cardColor
                          : kTransparent,
                      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).dividerColor,
                              width: 0.5,
                            )
                          : null,
                    ),
                    child: Text(
                      type.getDisplayName(context),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(
          width: 45,
          height: 45,
        ),
      ],
    );
  }
}
