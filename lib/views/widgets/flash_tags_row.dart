// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../routes/navigator.dart';
import '../../utils/utils.dart';
import '../search_view/search_view.dart';
import 'buttons_containers_widgets.dart';

class FlashTagsRow extends StatelessWidget {
  const FlashTagsRow({
    super.key,
    required this.isImportant,
    required this.tags,
    this.selectedTag,
  });

  final bool isImportant;
  final List<String> tags;

  final String? selectedTag;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isImportant) ...[
          _importantContainer(context),
          const SizedBox(
            width: kDefaultPadding / 4,
          )
        ],
        _tagsList(context),
      ],
    );
  }

  Container _importantContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(300),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            FeatureIcons.flame,
            height: 16,
            fit: BoxFit.fitHeight,
            colorFilter: const ColorFilter.mode(
              kWhite,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Text(
            context.t.important.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: kWhite,
                ),
          ),
        ],
      ),
    );
  }

  Expanded _tagsList(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 24,
        child: ScrollShadow(
          color: Theme.of(context).primaryColorLight,
          size: 10,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            separatorBuilder: (context, index) {
              return const SizedBox(
                width: kDefaultPadding / 4,
              );
            },
            itemBuilder: (context, index) {
              final tag = tags[index];
              if (tag.trim().isEmpty) {
                return const SizedBox.shrink();
              }

              return Center(
                child: InfoRoundedContainer(
                  tag: tag,
                  color: selectedTag != null && selectedTag == tag
                      ? kPurple
                      : Theme.of(context).cardColor,
                  textColor: Theme.of(context).primaryColorDark,
                  onClicked: () {
                    if (selectedTag == null || selectedTag != tag) {
                      YNavigator.pushPage(
                        context,
                        (context) => SearchView(
                          search: tag,
                          index: 1,
                        ),
                        type: PushPageType.opacity,
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
