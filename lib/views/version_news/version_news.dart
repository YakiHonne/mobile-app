// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../utils/utils.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/custom_icon_buttons.dart';

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        forceMaterialTransparency: true,
        toolbarHeight: kToolbarHeight,
        title: Text(
          context.t.updatesNews.capitalizeFirst(),
          style: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
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
      ),
      body: ScrollShadow(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
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
        decoration: const BoxDecoration(
            color: kMainColor,
            borderRadius: BorderRadius.only(
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
      child: CachedNetworkImage(
        imageUrl: e['thumbnail'].toString(),
        cacheManager: imagesCacheManager,
        memCacheWidth: MediaQuery.of(context).size.width.toInt(),
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                kDefaultPadding,
              ),
              border: Border.all(
                color: (e['new']! as bool) ? kMainColor : kTransparent,
                width: 1.5,
              ),
              image: DecorationImage(
                image: imageProvider,
              ),
            ),
          );
        },
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
              const DotContainer(
                color: kMainColor,
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

final List<String> releaseNotes = [
  // New Features
  'Receive share intent in-app',
  'Rearrange action buttons',
  'Add Hindi language',
  'Blur images for non-followers',

  // Improvements
  'Updated URLs (/r/notes, /r/content)',
  'Better GIF sizing',
  'Loading indicator in search bar',
  'Paginated transactions list',
  'Added DM loader & empty feed placeholder',

  // Fixes
  'Resolved note display, zap split, and nostr URL issues',
  'Fixed QR scanning, redeem controller, and shareable links',
  'Fixed unfollow button, mentions, and nip05 handling',
  'Improved notifications sync and stats loading with WoT',
  'Fixed nsec bunker setup, article markdown, and Blossom upload',
  'Reset search scroll position and made suggestions scrollable',
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
