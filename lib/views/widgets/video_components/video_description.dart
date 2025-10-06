// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../search_view/search_view.dart';
import '../buttons_containers_widgets.dart';
import '../dotted_container.dart';

class HVDescription extends StatelessWidget {
  const HVDescription({
    super.key,
    required this.title,
    required this.upvotes,
    required this.views,
    required this.tags,
    required this.createdAt,
    required this.description,
  });

  final String title;
  final String upvotes;
  final String views;
  final List<String> tags;
  final DateTime createdAt;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.40,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const ModalBottomSheetHandle(),
              Text(
                context.t.description.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              const Divider(
                height: 0,
              ),
              _content(scrollController, context),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _content(ScrollController scrollController, BuildContext context) {
    return Expanded(
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(
          kDefaultPadding / 1.5,
        ),
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _stats(context),
          if (tags.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding,
            ),
            _tagsList(context),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding,
            ),
            Container(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 2,
                ),
              ),
              child: ParsedText(text: description),
            ),
          ]
        ],
      ),
    );
  }

  SizedBox _tagsList(BuildContext context) {
    return SizedBox(
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
                color: Theme.of(context).highlightColor,
                textColor: Theme.of(context).primaryColorDark,
                onClicked: () {
                  YNavigator.pushPage(
                    context,
                    (context) => SearchView(
                      search: tag,
                      index: 3,
                    ),
                    type: PushPageType.opacity,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Row _stats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _descriptionColumn(
            context: context,
            description: context.t.upvotes.capitalizeFirst(),
            title: upvotes,
          ),
        ),
        Expanded(
          child: _descriptionColumn(
            context: context,
            description: context.t.views.capitalizeFirst(),
            title: views,
          ),
        ),
        Expanded(
          child: _descriptionColumn(
            context: context,
            description: createdAt.year.toString(),
            title: dateFormat6.format(createdAt),
          ),
        ),
      ],
    );
  }

  Column _descriptionColumn({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
