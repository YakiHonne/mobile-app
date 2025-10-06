import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/custom_app_bar.dart';

class UncensoredNoteExplanation extends StatelessWidget {
  const UncensoredNoteExplanation({super.key});
  static const routeName = '/uncensoredNoteExplanationView';
  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => const UncensoredNoteExplanation(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.explanation.capitalizeFirst(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Column(
              children: [
                Text(
                  context.t.readAboutVerifyingNotes.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Text(
                  context.t.readAboutVerifyingNotesDesc.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                TextButton(
                  onPressed: () {
                    openWebPage(
                      url:
                          'https://yakihonne.com/article/naddr1qq252nj4w4kkvan8dpuxx6f5x3n9xstk23tkyq3qyzvxlwp7wawed5vgefwfmugvumtp8c8t0etk3g8sky4n0ndvyxesxpqqqp65wpcr66x',
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: const VisualDensity(
                      vertical: -2,
                    ),
                  ),
                  child: Text(
                    context.t.readArticle.capitalizeFirst(),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(color: kWhite),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding),
              color: Theme.of(context).primaryColorLight,
            ),
            child: Column(
              children: [
                Text(
                  context.t.whyVerifyingNotes.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Row(
                  children: [
                    DotContainer(color: Theme.of(context).highlightColor),
                    Text(
                      context.t.contributeUnderstanding.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Row(
                  children: [
                    DotContainer(color: Theme.of(context).highlightColor),
                    Text(
                      context.t.actGoodFaith.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                Row(
                  children: [
                    DotContainer(color: Theme.of(context).highlightColor),
                    Text(
                      context.t.beHelpful.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                TextButton(
                  onPressed: () {
                    openWebPage(
                      url:
                          'https://yakihonne.com/article/naddr1qq2kw52htue8wez8wd9nj36pwucyx33hwsmrgq3qyzvxlwp7wawed5vgefwfmugvumtp8c8t0etk3g8sky4n0ndvyxesxpqqqp65w6998qf',
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: const VisualDensity(
                      vertical: -2,
                    ),
                  ),
                  child: Text(
                    context.t.readMore.capitalizeFirst(),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(color: kWhite),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
