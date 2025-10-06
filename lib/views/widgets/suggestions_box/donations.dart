import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/send_zaps_view/send_zaps_view.dart';

class SuggestedDonations extends StatelessWidget {
  const SuggestedDonations({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const PageStorageKey('suggested-donations'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 3.6,
            child: SvgPicture.asset(
              FeatureIcons.donationZaps,
            ),
          ),
          _content(context),
        ],
      ),
    );
  }

  Padding _content(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Column(
        children: [
          Text(
            context.t.supportYakihonne.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            context.t.fuelYakihonne.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _supportUs(context),
        ],
      ),
    );
  }

  SizedBox _supportUs(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          final metadata = await metadataCubit.getFutureMetadata(yakihonneHex);

          if (context.mounted) {
            doIfCanSign(
              func: () {
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
              },
              context: context,
            );
          }
        },
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
        ),
        child: Text(
          context.t.supportUs.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: kWhite,
              ),
        ),
      ),
    );
  }
}
