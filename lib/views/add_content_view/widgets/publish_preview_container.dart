import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/single_image_selector.dart';

class PublishPreviewContainer extends HookWidget {
  const PublishPreviewContainer({
    super.key,
    required this.descInitText,
    required this.onDescChanged,
    required this.imageLink,
    required this.onImageLinkChanged,
    required this.title,
    this.noDescription = false,
  });

  final String descInitText;
  final Function(String) onDescChanged;
  final String imageLink;
  final Function(String) onImageLinkChanged;
  final String title;
  final bool noDescription;

  @override
  Widget build(BuildContext context) {
    final summaryController = useTextEditingController(
      text: descInitText,
    );

    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.preview.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const Divider(
            thickness: 0.5,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (!noDescription) ...[
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryTextfield(summaryController, context),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              _imageContainer(),
            ],
          )
        ],
      ),
    );
  }

  Flexible _imageContainer() {
    return Flexible(
      flex: 2,
      child: Builder(builder: (context) {
        void addImage() {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) {
              return SingleImageSelector(
                onUrlProvided: onImageLinkChanged,
              );
            },
            backgroundColor: kTransparent,
            useRootNavigator: true,
            elevation: 0,
            useSafeArea: true,
          );
        }

        return GestureDetector(
          onTap: addImage,
          child: Column(
            children: [
              _imageThumbnail(context),
              if (imageLink.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                    context.t.uploadImage.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                )
              else
                _actionsRow(addImage, context)
            ],
          ),
        );
      }),
    );
  }

  IntrinsicHeight _actionsRow(Function() addImage, BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: addImage,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  context.t.edit.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          VerticalDivider(
            color: Theme.of(context).highlightColor,
            thickness: 0.5,
            indent: 5,
            endIndent: 5,
            width: 0,
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                onImageLinkChanged('');
              },
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Text(
                  context.t.delete.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: kRed,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  AspectRatio _imageThumbnail(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 1.5,
          ),
          border: Border.all(
            width: 0.5,
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: imageLink.isEmpty
            ? Center(
                child: SvgPicture.asset(
                  FeatureIcons.imageAttachment,
                  width: 25,
                  height: 25,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColorDark,
                    BlendMode.srcIn,
                  ),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) => CommonThumbnail(
                  image: imageLink,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  isRound: true,
                  radius: kDefaultPadding / 1.5,
                ),
              ),
      ),
    );
  }

  Expanded _summaryTextfield(
      TextEditingController summaryController, BuildContext context) {
    return Expanded(
      flex: 3,
      child: TextFormField(
        controller: summaryController,
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
        decoration: InputDecoration(
          hintText: noDescription
              ? context.t.title.capitalizeFirst()
              : context.t.writeSummary.capitalizeFirst(),
          contentPadding: EdgeInsets.zero,
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: kTransparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kTransparent),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kTransparent),
          ),
        ),
        minLines: 3,
        maxLines: 3,
        style: Theme.of(context).textTheme.bodyMedium,
        onChanged: onDescChanged,
      ),
    );
  }
}
