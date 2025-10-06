import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../utils/utils.dart';
import 'custom_icon_buttons.dart';

class ReactionsBox extends HookWidget {
  const ReactionsBox({
    super.key,
    required this.reactionButtonKey,
    required this.onReact,
    required this.buttonPosition,
    required this.buttonSize,
    required this.popupHeight,
    required this.displayOnLeft,
  });

  final GlobalKey reactionButtonKey;
  final Offset buttonPosition;
  final Size buttonSize;
  final double popupHeight;
  final Function(String) onReact;
  final bool displayOnLeft;

  @override
  Widget build(BuildContext context) {
    final isReduced = useState(true);
    final search = useState('');
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final positionBelow = buttonPosition.dy + buttonSize.height;
    final fitsBelow = positionBelow + popupHeight <= screenHeight;
    final topPosition = fitsBelow
        ? positionBelow - kToolbarHeight
        : isReduced.value
            ? positionBelow - kToolbarHeight - buttonSize.height - 55
            : positionBelow - popupHeight - kToolbarHeight - 55;

    final top = fitsBelow
        ? positionBelow >= (screenHeight - keyboardHeight - kToolbarHeight)
            ? topPosition - keyboardHeight
            : topPosition
        : topPosition;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          left: displayOnLeft ? 10.w : buttonPosition.dx,
          right: kDefaultPadding / 2,
          top: top,
          child: SingleChildScrollView(
            child: FutureBuilder(
                future: EmojiPickerUtils().getRecentEmojis(),
                builder: (context, snapshot) {
                  final ems = snapshot.hasData && snapshot.data!.isNotEmpty
                      ? snapshot.data!
                      : null;

                  return Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(
                      isReduced.value ? 300 : kDefaultPadding / 2,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(
                          isReduced.value ? 300 : kDefaultPadding / 2,
                        ),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                      child: AnimatedCrossFade(
                        crossFadeState: isReduced.value
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(milliseconds: 300),
                        firstChild: _emojisList(ems, isReduced),
                        secondChild: _emojiFullList(context, search, ems),
                      ),
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }

  SizedBox _emojiFullList(BuildContext context, ValueNotifier<String> search,
      List<RecentEmoji>? ems) {
    return SizedBox(
      height: popupHeight,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          onReact(emoji.emoji);
          Navigator.pop(context);
        },
        customWidget: (config, state, showSearchBar) {
          final emojis = config.emojiSet!(
            Localizations.localeOf(context),
          );

          return ListView(
            children: [
              CupertinoTextField(
                placeholder: context.t.search.capitalizeFirst(),
                style: Theme.of(context).textTheme.bodyMedium,
                placeholderStyle:
                    Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                onChanged: (s) {
                  search.value = s;
                },
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              if (search.value.isNotEmpty)
                _itemsGrid(emojis, search, state)
              else ...[
                if (ems != null)
                  _recentList(ems, state)
                else
                  const SizedBox.shrink(),
                for (final emojiCategory in emojis)
                  _categoriesGrid(emojiCategory, context, state),
              ],
            ],
          );
        },
      ),
    );
  }

  Padding _categoriesGrid(
      CategoryEmoji emojiCategory, BuildContext context, EmojiViewState state) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: kDefaultPadding / 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emojiCategory.category.name.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: Theme.of(context).highlightColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
            ),
            shrinkWrap: true,
            primary: false,
            itemCount: emojiCategory.emoji.length,
            itemBuilder: (context, index) {
              final e = emojiCategory.emoji[index];

              return GestureDetector(
                onTap: () {
                  state.onEmojiSelected.call(
                    emojiCategory.category,
                    e,
                  );
                },
                child: FittedBox(
                  child: Text(
                    e.emoji,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Padding _recentList(List<RecentEmoji> ems, EmojiViewState state) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: kDefaultPadding / 2,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.recent.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).highlightColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(
              height: constraints.maxWidth / 8,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final e = ems[index];

                  return GestureDetector(
                    onTap: () {
                      state.onEmojiSelected.call(
                        Category.ACTIVITIES,
                        e.emoji,
                      );
                    },
                    child: SizedBox(
                      height: constraints.maxWidth / 9,
                      width: constraints.maxWidth / 9,
                      child: FittedBox(
                        child: Text(
                          e.emoji.emoji,
                        ),
                      ),
                    ),
                  );
                },
                itemCount: ems.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Builder _itemsGrid(List<CategoryEmoji> emojis, ValueNotifier<String> search,
      EmojiViewState state) {
    return Builder(
      builder: (context) {
        final filteredEmojis = <Emoji>[];

        for (final e in emojis) {
          for (final emoji in e.emoji) {
            if (emoji.emoji.contains(search.value) ||
                emoji.name.contains(search.value)) {
              filteredEmojis.add(emoji);
            }
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.search.capitalizeFirst(),
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).highlightColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              shrinkWrap: true,
              primary: false,
              itemCount: filteredEmojis.length,
              itemBuilder: (context, index) {
                final e = filteredEmojis[index];

                return GestureDetector(
                  onTap: () {
                    state.onEmojiSelected.call(
                      Category.ACTIVITIES,
                      e,
                    );
                  },
                  child: FittedBox(
                    child: Text(
                      e.emoji,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Builder _emojisList(List<RecentEmoji>? ems, ValueNotifier<bool> isReduced) {
    return Builder(
      builder: (context) {
        final emojis = const Config().emojiSet!(
          Localizations.localeOf(context),
        );

        final reactions = ems?.map((e) => e.emoji.emoji).toList() ??
            emojis.first.emoji.map((e) => e.emoji).toList();

        return SizedBox(
          height: 25,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ScrollShadow(
                  color: Theme.of(context).cardColor,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (context, index) => const SizedBox(
                      width: kDefaultPadding / 4,
                    ),
                    itemBuilder: (context, index) {
                      final reaction = reactions[index];

                      return GestureDetector(
                        onTap: () {
                          onReact(reaction);
                          Navigator.pop(context);
                        },
                        child: FittedBox(
                          child: Text(
                            reaction,
                            style: const TextStyle(
                              height: 1,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: reactions.length,
                  ),
                ),
              ),
              const VerticalDivider(),
              CustomIconButton(
                onClicked: () {
                  isReduced.value = false;
                },
                icon: FeatureIcons.addRaw,
                size: 15,
                iconColor: Theme.of(context).highlightColor,
                backgroundColor: kTransparent,
                vd: -4,
              ),
            ],
          ),
        );
      },
    );
  }
}
