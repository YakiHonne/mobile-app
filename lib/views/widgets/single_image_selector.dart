import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../common/media_handler/media_handler.dart';
import '../../utils/utils.dart';
import 'app_icon.dart';
import 'custom_icon_buttons.dart';
import 'modal_sheet_container.dart';

class SingleImageSelector extends HookWidget {
  const SingleImageSelector({
    super.key,
    required this.onUrlProvided,
    this.title,
    this.description,
  });

  final Function(String, {Map<String, String>? imeta}) onUrlProvided;
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final toggleUrl = useState(false);
    final url = useState('');

    return ModalSheetContainer(
      child: Padding(
        padding: const EdgeInsets.only(
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          bottom: kBottomNavigationBarHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              title ?? context.t.pickYourImage.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Text(
              description ?? context.t.uploadPasteUrl.capitalizeFirst(),
              style: TextStyle(
                color: Theme.of(context).highlightColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            if (toggleUrl.value)
              _pasteYourLink(toggleUrl, context, url)
            else
              _actionsRow(context, toggleUrl),
            const SizedBox(
              height: kDefaultPadding * 1.5,
            ),
          ],
        ),
      ),
    );
  }

  Column _actionsRow(BuildContext context, ValueNotifier<bool> toggleUrl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: SingleImageChoice(
                  icon: FeatureIcons.link,
                  title: context.t.url.capitalizeFirst(),
                  mediaType: MediaType.cameraVideo,
                  onClicked: () {
                    toggleUrl.value = true;
                  },
                  onUrlProvided: onUrlProvided,
                ),
              ),
              const VerticalDivider(
                indent: kDefaultPadding / 2,
                endIndent: kDefaultPadding / 2,
              ),
              Expanded(
                child: SingleImageChoice(
                  icon: FeatureIcons.camera,
                  title: context.t.camera.capitalizeFirst(),
                  mediaType: MediaType.cameraImage,
                  onUrlProvided: onUrlProvided,
                ),
              ),
              const VerticalDivider(
                indent: kDefaultPadding / 2,
                endIndent: kDefaultPadding / 2,
              ),
              Expanded(
                child: SingleImageChoice(
                  icon: FeatureIcons.image,
                  title: context.t.gallery.capitalizeFirst(),
                  mediaType: MediaType.gallery,
                  onUrlProvided: onUrlProvided,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Column _pasteYourLink(ValueNotifier<bool> toggleUrl, BuildContext context,
      ValueNotifier<String> url) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => toggleUrl.value = false,
          child: Row(
            children: [
              const Icon(
                LucideIcons.chevronLeft,
                size: 15,
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Text(context.t.back.capitalizeFirst()),
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        TextField(
          decoration: InputDecoration(
            hintText: context.t.pasteYourLink.capitalizeFirst(),
            suffixIcon: url.value.isNotEmpty
                ? CustomIconButton(
                    onClicked: () {
                      onUrlProvided.call(url.value);
                    },
                    icon: FeatureIcons.widgetCorrect,
                    size: 20,
                    backgroundColor: Theme.of(context).cardColor,
                  )
                : null,
          ),
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (u) {
            url.value = u;
          },
        ),
      ],
    );
  }
}

class SingleImageChoice extends StatelessWidget {
  const SingleImageChoice({
    super.key,
    required this.mediaType,
    required this.title,
    required this.icon,
    this.onClicked,
    required this.onUrlProvided,
  });

  final MediaType mediaType;
  final String title;
  final IconData icon;
  final Function()? onClicked;
  final Function(String, {Map<String, String>? imeta}) onUrlProvided;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClicked ??
          () async {
            final data =
                await MediaHandler.selectMediaAndUploadWithData(mediaType);
            if (data != null && data['url'] != null) {
              onUrlProvided.call(data['url']!, imeta: data);
            }
          },
      child: Column(
        children: [
          AppIcon(
            icon,
            color: Theme.of(context).primaryColorDark,
            size: 30,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium,
          )
        ],
      ),
    );
  }
}
