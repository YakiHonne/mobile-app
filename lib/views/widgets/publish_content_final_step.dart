import 'package:flutter/material.dart';

import '../../models/app_models/popup_menu_common_item.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import '../article_view/article_view.dart';
import '../curation_view/curation_view.dart';
import '../smart_widgets_view/widgets/smart_widget_checker.dart';
import 'dotted_container.dart';
import 'video_components/horizontal_video_view.dart';
import 'video_components/vertical_video_view.dart';

class PublishContentFinalStep extends StatelessWidget {
  const PublishContentFinalStep({
    super.key,
    required this.appContentType,
    required this.event,
  });

  final AppContentType appContentType;
  final BaseEventModel event;

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
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Center(child: ModalBottomSheetHandle()),
            const SizedBox(
              height: kDefaultPadding / 1.5,
            ),
            SvgPicture.asset(
              FeatureIcons.widgetCorrect,
              width: 55,
              height: 55,
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            Text(
              context.t.itsLive.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              context.t.spreadWordSharingContent.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const Divider(
              thickness: 0.5,
              height: kDefaultPadding * 2,
            ),
            _options(context),
            const SizedBox(
              height: kBottomNavigationBarHeight,
            ),
          ],
        ),
      ),
    );
  }

  Row _options(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kDefaultPadding / 2,
      children: [
        _addToNote(context),
        if (appContentType == AppContentType.smartWidget) _shareImage(context),
        Expanded(
          child: PublishFinalStepOption(
            icon: FeatureIcons.shareGlobal,
            title: context.t.share.capitalizeFirst(),
            onClicked: () => PdmCommonActions.shareBaseEventModel(
              context,
              event,
            ),
          ),
        ),
        _viewPublishContent(context),
      ],
    );
  }

  Expanded _shareImage(BuildContext context) {
    return Expanded(
      child: PublishFinalStepOption(
        icon: FeatureIcons.image,
        title: context.t.shareImage.capitalizeFirst(),
        onClicked: () {
          YNavigator.pop(context);

          YNavigator.pushPage(
            context,
            (context) => AddContentView(
              contentType: AppContentType.note,
              content: (event as SmartWidget).smartWidgetBox.image.url,
            ),
          );
        },
      ),
    );
  }

  Expanded _addToNote(BuildContext context) {
    return Expanded(
      child: PublishFinalStepOption(
        icon: FeatureIcons.addNote,
        title: context.t.postInNote.capitalizeFirst(),
        onClicked: () {
          YNavigator.pop(context);
          YNavigator.pushPage(
            context,
            (context) => AddContentView(
              attachedEvent: event,
              contentType: AppContentType.note,
              isMention: true,
            ),
          );
        },
      ),
    );
  }

  Expanded _viewPublishContent(BuildContext context) {
    return Expanded(
      child: PublishFinalStepOption(
        icon: FeatureIcons.visible,
        title: context.t.view.capitalizeFirst(),
        onClicked: () {
          if (appContentType == AppContentType.article) {
            YNavigator.pushPage(
              context,
              (context) => ArticleView(article: event as Article),
            );
          } else if (appContentType == AppContentType.curation) {
            YNavigator.pushPage(
              context,
              (context) => CurationView(curation: event as Curation),
            );
          } else if (appContentType == AppContentType.smartWidget) {
            YNavigator.pushPage(
              context,
              (context) => SmartWidgetChecker(
                naddr: (event as SmartWidget).getNaddr(),
                swm: event as SmartWidget,
              ),
            );
          } else if (appContentType == AppContentType.video) {
            final video = event as VideoModel;

            YNavigator.pushPage(
              context,
              (context) => video.isHorizontal
                  ? HorizontalVideoView(video: video)
                  : VerticalVideoView(video: video),
            );
          }
        },
      ),
    );
  }
}

class PublishFinalStepOption extends StatelessWidget {
  const PublishFinalStepOption({
    super.key,
    required this.icon,
    required this.title,
    required this.onClicked,
  });

  final String icon;
  final String title;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
            ),
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            child: SvgPicture.asset(
              icon,
              width: 25,
              height: 25,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 3,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
