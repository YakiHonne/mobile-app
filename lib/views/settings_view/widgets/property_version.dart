import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../utils/utils.dart';
import '../../logify_view/widgets/eula_view.dart';
import '../../version_news/version_news.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';
import '../../widgets/buttons_containers_widgets.dart';
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
              _legalLinks(context),
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

  Widget _legalLinks(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
          color: Theme.of(context).highlightColor,
        );

    Widget legalButton(String title, String path) {
      return GestureDetector(
        onTap: () => openWebPage(url: '$baseUrl$path'),
        child: Text(title, style: style),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        legalButton(context.t.privacyPolicies.capitalizeFirst(), 'privacy'),
        DotContainer(color: Theme.of(context).highlightColor),
        legalButton(
          context.t.termsAndConditions.capitalizeFirst(),
          'terms',
        ),
        DotContainer(color: Theme.of(context).highlightColor),
        legalButton(context.t.refundPolicy.capitalizeFirst(), 'refund-policy'),
      ],
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
          child: SvgPicture.asset(
            LogosIcons.logoMark,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
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
        Icon(
          LucideIcons.chevronRight,
          size: 20,
          color: Theme.of(context).primaryColor,
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
              showAdaptiveModal(
                context,
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
          icon: LucideIcons.code2,
          widget: SvgPicture.asset(
            FeatureIcons.github,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          size: 20,
          backgroundColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}
