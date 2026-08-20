import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';
import '../../polls_view/zap_polls_selection.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_sheet.dart' show showAppModalSheet;
import '../../write_zap_poll_view/write_zap_poll_view.dart';

class PollOptions extends HookWidget {
  const PollOptions({
    super.key,
    required this.onDataAdded,
  });

  final Function(String) onDataAdded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
      child: Container(
        width: 100.w,
        margin: const EdgeInsets.all(kDefaultPadding),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding * 2),
          color: Theme.of(context).cardColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalBottomSheetHandle(),
            Text(
              context.t.zapPoll,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: kDefaultPadding / 1.5,
            ),
            IntrinsicHeight(
              child: Row(
                spacing: kDefaultPadding / 3,
                children: [
                  _addZapPoll(context),
                  _browsePolls(context),
                ],
              ),
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
        ),
      ),
    );
  }

  Expanded _browsePolls(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showAppModalSheet(
            context: context,
            builder: (_) {
              return ZapPollSelection(
                onZapPollAdded: (ev) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  onDataAdded.call(ev.getNEvent());
                },
              );
            },
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                FeatureIcons.polls,
                color: Theme.of(context).primaryColorDark,
                size: 25,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                context.t.browsePolls.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium,
              )
            ],
          ),
        ),
      ),
    );
  }

  Expanded _addZapPoll(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          showAppModalSheet(
            context: context,
            builder: (_) {
              return WriteZapPollView(
                onZapPollAdded: (ev) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  onDataAdded.call(ev.getNEvent());
                },
              );
            },
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(
              color: Theme.of(context).scaffoldBackgroundColor,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                FeatureIcons.addRaw,
                color: Theme.of(context).primaryColorDark,
                size: 25,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                context.t.createPoll.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium,
              )
            ],
          ),
        ),
      ),
    );
  }
}
