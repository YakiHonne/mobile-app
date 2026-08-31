// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../utils/utils.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/custom_icon_buttons.dart';
import '../widgets/fluid_scaffold.dart';

class VersionNews extends StatefulWidget {
  const VersionNews({
    super.key,
    required this.onClosed,
  });
  final Function() onClosed;
  @override
  State<VersionNews> createState() => _VersionNewsState();
}

class _VersionNewsState extends State<VersionNews> {
  @override
  void dispose() {
    widget.onClosed.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FluidScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      notElevated: true,
      title: context.t.updatesNews.capitalizeFirst(),
      // Dismissed with the close button, so no back chevron and no logo.
      leading: Center(
        child: CustomIconButton(
          onClicked: () {
            Navigator.pop(context);
          },
          icon: FeatureIcons.closeRaw,
          size: 20,
          iconColor: Theme.of(context).primaryColorDark,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      ),
      actions: const [],
      body: ScrollShadow(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding / 2)
              .copyWith(top: kDefaultPadding / 2 + fluidScaffoldTopInset(context)),
          children: [
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _releaseNotes(context),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            ...content.map(
              (e) => Padding(
                padding: const EdgeInsets.only(
                  bottom: kDefaultPadding / 2,
                ),
                child: _versionStack(e, context),
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
      ),
    );
  }

  GestureDetector _versionStack(Map<String, Object> e, BuildContext context) {
    return GestureDetector(
      onTap: () {
        final url = '$baseUrl${e['url']}';
        openWebPage(url: url, openInternal: false);
      },
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          _thumbnail(e, context),
          _tag(e, context),
          if (e['new']! as bool) _newVersion(context),
        ],
      ),
    );
  }

  Positioned _newVersion(BuildContext context) {
    return Positioned(
      top: 1,
      left: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 1.5,
          vertical: kDefaultPadding / 4,
        ),
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(kDefaultPadding),
              bottomRight: Radius.circular(kDefaultPadding),
            )),
        child: Text(
          'New',
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
      ),
    );
  }

  Positioned _tag(Map<String, Object> e, BuildContext context) {
    return Positioned(
      top: 1,
      left: 1,
      child: Container(
        padding: EdgeInsets.only(
          right: kDefaultPadding / 1.5,
          left: (e['new']! as bool) ? 65 : kDefaultPadding / 1.5,
          bottom: kDefaultPadding / 4,
          top: kDefaultPadding / 4,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF555555),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(kDefaultPadding),
            bottomRight: Radius.circular(kDefaultPadding),
          ),
        ),
        child: Text(
          e['tag'].toString(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
      ),
    );
  }

  AspectRatio _thumbnail(Map<String, Object> e, BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ExtendedImage.network(
        e['thumbnail'].toString(),
        fit: BoxFit.scaleDown,
        cacheWidth: MediaQuery.of(context).size.width.toInt(),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(
          kDefaultPadding,
        ),
        border: Border.all(
          color: (e['new']! as bool)
              ? Theme.of(context).primaryColor
              : kTransparent,
          width: 1.5,
        ),
      ),
    );
  }

  Container _releaseNotes(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).cardColor,
      ),
      padding: const EdgeInsets.all(
        kDefaultPadding / 2,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${context.t.updates.capitalizeFirst()} ',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              DotContainer(
                color: Theme.of(context).primaryColor,
                size: 4,
              ),
              Text(
                appVersion,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          ...releaseNotes.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 4,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DotContainer(
                      color: Theme.of(context).highlightColor,
                      isNotMarging: true,
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: e,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }
}

/// Shown under [appVersion], so this list must be rewritten every release —
/// it shipped once already holding the previous version's notes.
final List<String> releaseNotes = [
  'Leading notes and replies now support kind 1111 comments, both reading and posting.',
  'Rewritten paid-note publishing with live payment tracking and automatic publishing once paid, plus a new published-confirmation screen.',
  'Redesigned pricing with a Free plan card and a full plan comparison.',
  'Your username now always shows in edit profile; claim it for free or subscribe if needed.',
  'Second Reader now matches the AI action to each paragraph, and the AI assistant stays open after processing.',
  'The editor warns before discarding article, AI discussion, and Second Reader data.',
  'Article view now shows a premium badge, the relay an event was seen on, word count, and read time.',
  'Videos support landscape and have smoother controls.',
  'Removed the 800 sats zap preset.',
  'General bug fixes and performance enhancements.',
];

const content = [
  {
    'url': 'yakihonne-smart-widgets',
    'thumbnail':
        'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/update-smart-widget.png',
    'tag': 'Smart widgets',
    'new': false,
  },
  {
    'url': 'points-system',
    'thumbnail':
        'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/update-points-system.png',
    'tag': 'Points system',
    'new': false,
  },
  {
    'url': 'yakihonne-flash-news',
    'thumbnail':
        'https://yakihonne.s3.ap-east-1.amazonaws.com/sw-thumbnails/update-flash-news.png',
    'tag': 'Paid notes',
    'new': false,
  },
];
