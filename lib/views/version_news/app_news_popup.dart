import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../widgets/buttons_containers_widgets.dart';
import '../widgets/custom_icon_buttons.dart';
import 'version_news.dart';

class AppNewsPopup extends StatelessWidget {
  const AppNewsPopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Theme.of(context).cardColor,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.t.whatsNew.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                _version(context),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                _releaseNotes(context),
              ],
            ),
          ),
          Positioned(
            right: -12,
            top: -12,
            child: CustomIconButton(
              onClicked: () {
                Navigator.of(context).pop();
              },
              icon: FeatureIcons.closeRaw,
              size: 15,
              vd: -2,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }

  SizedBox _releaseNotes(BuildContext context) {
    return SizedBox(
      height: 25.h,
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: ListView(
          children: [
            ...releaseNotes.map(
              (e) {
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Row _version(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          appVersion,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        const DotContainer(
          color: kMainColor,
          size: 5,
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              createViewFromBottom(VersionNews(onClosed: () {})),
            );
          },
          child: Text(
            context.t.seeMore.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ],
    );
  }
}
