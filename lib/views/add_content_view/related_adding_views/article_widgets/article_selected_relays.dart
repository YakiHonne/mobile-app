// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../utils/utils.dart';
import 'article_details.dart';

class ArticleSelectedRelays extends StatelessWidget {
  const ArticleSelectedRelays({
    super.key,
    required this.totaRelays,
    required this.selectedRelays,
    required this.onToggle,
    required this.onDeleteDraft,
    required this.isDraft,
    required this.deleteDraft,
    required this.isForwardedAsDraft,
    required this.isDraftShown,
  });

  final List<String> totaRelays;
  final List<String> selectedRelays;
  final Function(String) onToggle;
  final Function() onDeleteDraft;
  final bool isDraft;
  final bool deleteDraft;
  final bool isForwardedAsDraft;
  final bool isDraftShown;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final isDark = themeCubit.isDark;

    return FadeInRight(
      duration: const Duration(milliseconds: 300),
      child: ListView(
        padding: EdgeInsets.all(isTablet ? 10.w : kDefaultPadding / 2),
        children: [
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            '(for more custom relays, check your settings)',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          if (ResponsiveBreakpoints.of(context).largerThan(MOBILE))
            _gridRelays(isDark)
          else
            _columnRelays(isDark),
          if (isDraftShown && isDraft && !isForwardedAsDraft)
            Column(
              children: [
                const SizedBox(
                  height: kDefaultPadding / 3,
                ),
                ArticleCheckBoxListTile(
                  isEnabled: true,
                  status: deleteDraft,
                  text: context.t.publishRemoveDraft,
                  onToggle: onDeleteDraft,
                )
              ],
            ),
        ],
      ),
    );
  }

  Column _columnRelays(bool isDark) {
    return Column(
      children: totaRelays
          .map(
            (relay) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 4,
              ),
              child: ArticleCheckBoxListTile(
                isEnabled: !mandatoryRelays.contains(relay),
                onToggle: () => onToggle(relay),
                status: selectedRelays.contains(relay) ||
                    mandatoryRelays.contains(relay),
                text: relay.split('wss://')[1],
                textColor: mandatoryRelays.contains(relay)
                    ? isDark
                        ? kLightPurple
                        : kPurple
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }

  MasonryGridView _gridRelays(bool isDark) {
    return MasonryGridView.builder(
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      shrinkWrap: true,
      primary: false,
      crossAxisSpacing: kDefaultPadding / 2,
      itemCount: totaRelays.length,
      itemBuilder: (context, index) {
        final relay = totaRelays[index];

        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding / 4,
          ),
          child: ArticleCheckBoxListTile(
            isEnabled: !mandatoryRelays.contains(relay),
            onToggle: () => onToggle(relay),
            status: selectedRelays.contains(relay) ||
                mandatoryRelays.contains(relay),
            text: relay.split('wss://')[1],
            textColor: mandatoryRelays.contains(relay)
                ? isDark
                    ? kLightPurple
                    : kPurple
                : null,
          ),
        );
      },
    );
  }
}
