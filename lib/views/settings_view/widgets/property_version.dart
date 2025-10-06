import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../utils/utils.dart';
import '../../logify_view/widgets/eula_view.dart';
import '../../version_news/version_news.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../../widgets/custom_icon_buttons.dart';

class PropertyVersion extends StatelessWidget {
  const PropertyVersion({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          createViewFromBottom(
            VersionNews(
              onClosed: () {},
            ),
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
          child: Column(
            children: [
              _version(context),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                context.t.striveToMake.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              _infos(context),
            ],
          ),
        ),
      ),
    );
  }

  Row _version(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 35,
          height: 35,
          padding: const EdgeInsets.all(kDefaultPadding / 4),
          decoration: BoxDecoration(
            color: kPurple,
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          child: SvgPicture.asset(LogosIcons.logoMarkWhite),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.yakihonne.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).highlightColor),
            ),
            Text(
              appVersion,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 20,
          color: kMainColor,
        )
      ],
    );
  }

  Row _infos(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kDefaultPadding / 2,
      children: [
        CustomIconButton(
          onClicked: () async {
            final metadata =
                await metadataCubit.getFutureMetadata(yakihonneHex);

            if (context.mounted) {
              showModalBottomSheet(
                elevation: 0,
                context: context,
                builder: (_) {
                  return SendZapsView(
                    metadata: metadata ??
                        Metadata.empty().copyWith(
                          pubkey: yakihonneHex,
                          lud16: 'yakihonne@getalby.com',
                        ),
                    isZapSplit: false,
                    zapSplits: const [],
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          },
          icon: FeatureIcons.zap,
          size: 20,
          backgroundColor: Theme.of(context).cardColor,
        ),
        CustomIconButton(
          onClicked: () {
            sendEmail();
          },
          icon: FeatureIcons.message,
          size: 20,
          backgroundColor: Theme.of(context).cardColor,
        ),
        CustomIconButton(
          onClicked: () {
            openWebPage(
              url: 'https://github.com/orgs/YakiHonne/repositories',
            );
          },
          icon: FeatureIcons.github,
          size: 20,
          backgroundColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}
