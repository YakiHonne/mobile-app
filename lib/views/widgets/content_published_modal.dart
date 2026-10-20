import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/app_models/popup_menu_common_item.dart';
import '../../models/article_model.dart';
import '../../models/curation_model.dart';
import '../../models/detailed_note_model.dart';
import '../../models/flash_news_model.dart';
import '../../models/picture_model.dart';
import '../../models/smart_widgets_components.dart';
import '../../models/video_model.dart';
import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../add_content_view/add_content_view.dart';
import '../article_view/article_view.dart';
import '../curation_view/curation_view.dart';
import '../note_view/note_view.dart';
import '../smart_widgets_view/widgets/smart_widget_checker.dart';
import 'app_icon.dart';
import 'buttons_containers_widgets.dart';
import 'common_thumbnail.dart';
import 'data_providers.dart';
import 'fluid_sheet.dart';
import 'media_components/horizontal_video_view.dart';
import 'media_components/picture_view.dart';
import 'media_components/vertical_video_view.dart';
import 'modal_sheet_container.dart';
import 'profile_picture.dart';

void showContentPublishedModalSheet(
  BuildContext context, {
  required BaseEventModel event,
  required AppContentType contentType,
  bool isPaid = false,
}) {
  showAppModalSheet(
    context: context,
    builder: (_) => ContentPublishedModalSheet(
      event: event,
      contentType: contentType,
      isPaid: isPaid,
    ),
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  );
}

class ContentPublishedModalSheet extends StatelessWidget {
  const ContentPublishedModalSheet({
    super.key,
    required this.event,
    required this.contentType,
    this.isPaid = false,
  });

  final BaseEventModel event;
  final AppContentType contentType;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModalSheetContainer(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding,
            vertical: kDefaultPadding / 2,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppIconButton(
                    icon: LucideIcons.x,
                    onClicked: () => YNavigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding / 2),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: kGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.check,
                    color: kWhite,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              Text(
                context.t
                    .contentIsLive(contentType: _contentTypeLabel(context))
                    .capitalizeFirst(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: kDefaultPadding / 4),
              Text(
                context.t.spreadWordSharingContent.capitalizeFirst(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              _buildPreviewCard(context, theme),
              const SizedBox(height: kDefaultPadding * 1.5),
              _options(context),
              const SizedBox(height: kDefaultPadding / 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _options(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: kDefaultPadding / 4,
      runSpacing: kDefaultPadding / 2,
      children: [
        PublishFinalStepOption(
          icon: FeatureIcons.addNote,
          title: context.t.postInNote.capitalizeFirst(),
          onClicked: () {
            YNavigator.pop(context);

            YNavigator.pushPage(
              context,
              (_) => AddContentView(
                attachedEvent: event,
                contentType: AppContentType.note,
                isMention: true,
              ),
            );
          },
        ),
        if (contentType == AppContentType.smartWidget)
          PublishFinalStepOption(
            icon: FeatureIcons.image,
            title: context.t.shareImage.capitalizeFirst(),
            onClicked: () {
              YNavigator.pop(context);

              YNavigator.pushPage(
                context,
                (_) => AddContentView(
                  contentType: AppContentType.note,
                  content: (event as SmartWidget).smartWidgetBox.image.url,
                ),
              );
            },
          ),
        PublishFinalStepOption(
          icon: FeatureIcons.shareGlobal,
          title: context.t.share.capitalizeFirst(),
          onClicked: () => PdmCommonActions.shareBaseEventModel(
            context,
            event,
          ),
        ),
        PublishFinalStepOption(
          icon: FeatureIcons.visible,
          title: context.t.view.capitalizeFirst(),
          onClicked: () => _viewPublishContent(context),
        ),
      ],
    );
  }

  void _viewPublishContent(BuildContext context) {
    YNavigator.pop(context);

    switch (contentType) {
      case AppContentType.note:
        YNavigator.pushPage(
          context,
          (_) => NoteView(note: event as DetailedNoteModel),
        );
      case AppContentType.article:
        YNavigator.pushPage(
          context,
          (_) => ArticleView(article: event as Article),
        );
      case AppContentType.curation:
        YNavigator.pushPage(
          context,
          (_) => CurationView(curation: event as Curation),
        );
      case AppContentType.smartWidget:
        YNavigator.pushPage(
          context,
          (_) => SmartWidgetChecker(
            naddr: (event as SmartWidget).getScheme(),
            swm: event as SmartWidget,
          ),
        );
      case AppContentType.video:
        final video = event as VideoModel;

        YNavigator.pushPage(
          context,
          (_) => video.isHorizontal
              ? HorizontalVideoView(video: video)
              : VerticalVideoView(video: video),
        );
      case AppContentType.picture:
        YNavigator.pushPage(
          context,
          (_) => PictureView(picture: event as PictureModel),
        );
    }
  }

  String _contentTypeLabel(BuildContext context) {
    switch (contentType) {
      case AppContentType.note:
        return context.t.note;
      case AppContentType.article:
        return context.t.article;
      case AppContentType.smartWidget:
        return context.t.smartWidget;
      case AppContentType.video:
        return context.t.video;
      case AppContentType.curation:
        return context.t.curation;
      case AppContentType.picture:
        return context.t.image;
    }
  }

  Widget _buildPreviewCard(BuildContext context, ThemeData theme) {
    final isMedia = contentType != AppContentType.note;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
        border: Border.all(
          color: theme.dividerColor,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMedia) _thumbnail(),
            Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metadataHeader(context, theme),
                  const SizedBox(height: kDefaultPadding / 1.5),
                  _previewContent(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metadataHeader(BuildContext context, ThemeData theme) {
    return MetadataProvider(
      key: ValueKey(event.pubkey),
      pubkey: event.pubkey,
      child: (metadata, isNip05Valid) {
        final npub = Nip19.encodePubkey(event.pubkey);
        final handleStr = metadata.name.isNotEmpty
            ? '@${metadata.name}'
            : '@${npub.substring(0, npub.length > 10 ? 10 : npub.length)}...';

        return Row(
          children: [
            ProfilePicture2(
              image: isUserMuted(event.pubkey) ? '' : metadata.picture,
              pubkey: event.pubkey,
              size: 36,
              padding: 0,
              strokeWidth: 0,
              strokeColor: kTransparent,
              onClicked: () {},
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUserMuted(event.pubkey)
                        ? context.t.mutedUser
                        : metadata.getName(),
                    style: theme.textTheme.labelLarge!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$handleStr · ${context.t.justNow}',
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPaid) ...[
              const SizedBox(width: kDefaultPadding / 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE040FB),
                      Color(0xFFFF9100),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(300),
                ),
                child: Text(
                  context.t.paid.capitalizeFirst(),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: kWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _previewContent(ThemeData theme) {
    switch (contentType) {
      case AppContentType.note:
        final note = event as DetailedNoteModel;
        return Text(
          note.content,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        );
      case AppContentType.article:
        final article = event as Article;
        return _titledBody(theme, article.title, article.summary);
      case AppContentType.video:
        final video = event as VideoModel;
        return _titledBody(theme, video.title, video.summary);
      case AppContentType.picture:
        final picture = event as PictureModel;
        return _titledBody(
          theme,
          picture.title.isNotEmpty ? picture.title : picture.content,
          picture.title.isNotEmpty ? picture.content : '',
        );
      case AppContentType.curation:
        final curation = event as Curation;
        return _titledBody(
          theme,
          curation.title.isNotEmpty ? curation.title : curation.description,
          curation.title.isNotEmpty ? curation.description : '',
        );
      case AppContentType.smartWidget:
        final smartWidget = event as SmartWidget;
        return _titledBody(theme, smartWidget.title, '');
    }
  }

  Widget _thumbnail() {
    String image;
    switch (contentType) {
      case AppContentType.article:
        image = (event as Article).image;
      case AppContentType.video:
        image = (event as VideoModel).thumbnail;
      case AppContentType.picture:
        final picture = event as PictureModel;
        image = picture.images.isNotEmpty ? picture.images.first.url : '';
      case AppContentType.curation:
        image = (event as Curation).image;
      case AppContentType.smartWidget:
        image = (event as SmartWidget).image;
      case AppContentType.note:
        image = '';
    }

    if (image.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return CommonThumbnail(
      image: image,
      width: double.infinity,
      height: kDefaultPadding * 5,
      radius: 0,
      fit: BoxFit.cover,
    );
  }

  Widget _titledBody(
    ThemeData theme,
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description.trim().isNotEmpty) ...[
          const SizedBox(height: kDefaultPadding / 4),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium!.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ],
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

  final IconData icon;
  final String title;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onClicked,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            icon,
            size: 16,
            color: theme.primaryColorDark,
          ),
          const SizedBox(width: kDefaultPadding / 3),
          Text(
            title,
            style: theme.textTheme.labelLarge!.copyWith(
              color: theme.highlightColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
