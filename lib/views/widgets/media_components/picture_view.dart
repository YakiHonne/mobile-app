import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/picture_cubit/picture_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/picture_model.dart';
import '../../../utils/utils.dart';
import '../../gallery_view/gallery_view.dart';
import '../data_providers.dart';
import '../no_content_widgets.dart';
import '../note_stats.dart';
import '../profile_picture.dart';

class PictureView extends StatefulWidget {
  const PictureView({super.key, required this.picture});

  final PictureModel picture;

  @override
  State<PictureView> createState() => _PictureViewState();
}

class _PictureViewState extends State<PictureView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PictureCubit(
        pictureModel: widget.picture,
      ),
      child: BlocBuilder<PictureCubit, PictureState>(
        builder: (context, state) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            bottomNavigationBar: _bottomNavBar(context),
            body: BlocBuilder<PictureCubit, PictureState>(
              builder: (context, state) {
                return isUserMuted(widget.picture.pubkey)
                    ? Center(
                        child: MutedUserContent(
                          pubkey: widget.picture.pubkey,
                        ),
                      )
                    : Center(child: _content(context, state));
              },
            ),
          );
        },
      ),
    );
  }

  Visibility _bottomNavBar(BuildContext context) {
    return Visibility(
      visible: !isUserMuted(widget.picture.pubkey),
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        height:
            kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
        child: Column(
          children: [
            const Divider(
              height: 0,
              thickness: 0.5,
            ),
            const SizedBox(height: kDefaultPadding / 2),
            SizedBox(
              height: kBottomNavigationBarHeight,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: NoteStats(
                  id: widget.picture.id,
                  model: widget.picture,
                  isMain: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PictureState state) {
    final entry = MapEntry(widget.picture.getUrl(), UrlType.image);

    return Stack(
      children: [
        const SizedBox.expand(),
        Positioned.fill(
          child: OpenGalleryWidget(
            media: [entry],
            index: 0,
            entry: entry,
            isGallery: false,
            isRound: false,
            addBlackLayer: true,
          ),
        ),
        Positioned(
          bottom: kDefaultPadding,
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          child: MediaInfoColumn(
            pubkey: widget.picture.pubkey,
            title: widget.picture.title,
            content: widget.picture.content,
            createdAt: widget.picture.createdAt,
            onFollowAction: () {
              if (canSign()) {
                context.read<PictureCubit>().setFollowingState();
              }
            },
          ),
        )
      ],
    );
  }
}

class MediaInfoColumn extends StatelessWidget {
  const MediaInfoColumn({
    super.key,
    required this.pubkey,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.onFollowAction,
  });

  final String pubkey;
  final String title;
  final String content;
  final DateTime createdAt;
  final Function() onFollowAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: kDefaultPadding / 4,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetadataProvider(
          pubkey: pubkey,
          child: (metadata, isNip05Valid) => Row(
            children: [
              ProfilePicture3(
                size: 30,
                image: metadata.picture,
                pubkey: metadata.pubkey,
                padding: 0,
                strokeWidth: 0,
                reduceSize: true,
                strokeColor: kTransparent,
                onClicked: () {
                  openProfileFastAccess(
                    context: context,
                    pubkey: metadata.pubkey,
                  );
                },
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            metadata.getName(),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                              color: kWhite,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                const Shadow(
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isNip05Valid)
                          Row(
                            children: [
                              const SizedBox(
                                width: kDefaultPadding / 4,
                              ),
                              SvgPicture.asset(
                                FeatureIcons.verified,
                                width: 15,
                                height: 15,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).primaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ],
                          )
                      ],
                    ),
                    Text(
                      dateFormat2.format(createdAt),
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: kWhite,
                        shadows: [
                          const Shadow(
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Builder(
                builder: (context) {
                  final isDisabled =
                      !canSign() || currentSigner!.getPublicKey() == pubkey;

                  return AbsorbPointer(
                    absorbing: isDisabled,
                    child: TextButton(
                      onPressed: onFollowAction,
                      style: TextButton.styleFrom(
                        visualDensity: const VisualDensity(
                          vertical: -1,
                        ),
                        backgroundColor: isDisabled
                            ? Theme.of(context).highlightColor
                            : contactListCubit.contacts.contains(pubkey)
                                ? Theme.of(context).cardColor
                                : Theme.of(context).primaryColor,
                      ),
                      child: Text(
                        contactListCubit.contacts.contains(pubkey)
                            ? context.t.unfollow.capitalizeFirst()
                            : context.t.follow.capitalizeFirst(),
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: contactListCubit.contacts.contains(pubkey)
                                  ? Theme.of(context).primaryColorDark
                                  : kWhite,
                            ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
            ],
          ),
        ),
        if (title.isNotEmpty)
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w600,
              shadows: [
                const Shadow(
                  blurRadius: 5,
                )
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (content.isNotEmpty)
          ExpandableDescription(
            content: content,
            textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
              shadows: [
                const Shadow(
                  blurRadius: 5,
                )
              ],
            ),
          ),
      ],
    );
  }
}

class ExpandableDescription extends StatefulWidget {
  const ExpandableDescription({
    super.key,
    required this.content,
    required this.textStyle,
  });

  final String content;
  final TextStyle textStyle;

  @override
  State<ExpandableDescription> createState() => ExpandableDescriptionState();
}

class ExpandableDescriptionState extends State<ExpandableDescription> {
  bool _isExpanded = false;
  bool _exceedsTwoLines = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTextLength();
    });
  }

  void _checkTextLength() {
    final textSpan = TextSpan(
      text: widget.content,
      style: widget.textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
        maxWidth: MediaQuery.of(context).size.width - kDefaultPadding);

    if (mounted) {
      setState(() {
        _exceedsTwoLines = textPainter.didExceedMaxLines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_exceedsTwoLines) {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kDefaultPadding / 4,
        children: [
          Expanded(
            child: _isExpanded
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: widget.textStyle.fontSize! *
                          widget.textStyle.height! *
                          5,
                    ),
                    child: SingleChildScrollView(
                      child: ParsedText(
                        text: widget.content,
                        disableNoteParsing: true,
                        disableUrlParsing: true,
                        style: widget.textStyle,
                      ),
                    ),
                  )
                : ParsedText(
                    text: widget.content,
                    disableNoteParsing: true,
                    disableUrlParsing: true,
                    style: widget.textStyle,
                    maxLines: 2,
                  ),
          ),
          if (_exceedsTwoLines)
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: kWhite,
              size: 20,
              shadows: const [
                Shadow(
                  blurRadius: 5,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
