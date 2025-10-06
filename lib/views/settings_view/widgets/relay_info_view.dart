// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../../utils/utils.dart';
import '../../widgets/content_manager/dicover_settings_views/relay_settings_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/profile_picture.dart';

class RelayInfoView extends HookWidget {
  RelayInfoView({
    super.key,
    required this.relayInfo,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Relays info view');
  }

  final RelayInfo relayInfo;

  static const routeName = '/relayInfoView';
  static Route route(RouteSettings settings) {
    final relayInfo = settings.arguments! as RelayInfo;

    return CupertinoPageRoute(
      builder: (_) => RelayInfoView(
        relayInfo: relayInfo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      metadataCubit.requestMetadata(relayInfo.pubkey);
    });
    return Scaffold(
      appBar: CustomAppBar(
        title: relayInfo.name,
      ),
      body: ListView(
        padding: const EdgeInsets.all(
          kDefaultPadding / 2,
        ),
        children: [
          Row(
            children: [
              RelayImage(
                isSelected: false,
                url: relayInfo.icon,
                relayInfo: relayInfo,
                size: 60,
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relayInfo.name,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      relayInfo.url,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                            color: Theme.of(context).highlightColor,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(
            thickness: 0.3,
            height: kDefaultPadding * 1.5,
            color: Theme.of(context).highlightColor.withValues(alpha: 0.5),
          ),
          RelayGeneralInfo(relayInfo: relayInfo),
        ],
      ),
    );
  }
}

class RelayGeneralInfo extends StatelessWidget {
  const RelayGeneralInfo({
    super.key,
    required this.relayInfo,
    this.isCard = false,
  });

  final RelayInfo relayInfo;
  final bool isCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (relayInfo.description.isNotEmpty) ...[
          Text(
            context.t.description.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            relayInfo.description,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(),
          ),
          Divider(
            thickness: 0.3,
            height: kDefaultPadding,
            color: Theme.of(context).highlightColor.withValues(alpha: 0.5),
          ),
        ],
        if (relayInfo.getPubkey().isNotEmpty) _ownerRow(context),
        if (relayInfo.contact.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          infoRow(
            context: context,
            title: context.t.contact.toUpperCase(),
            text: relayInfo.contact.replaceAll('mailto:', ''),
          ),
        ],
        if (relayInfo.software.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          infoRow(
            context: context,
            title: context.t.software.toUpperCase(),
            text: relayInfo.software.split('/').last,
          ),
        ],
        if (relayInfo.version.isNotEmpty) ...[
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          infoRow(
            context: context,
            title: context.t.version.toUpperCase(),
            text: relayInfo.version,
          ),
        ],
        if (relayInfo.nips.isNotEmpty) ...[
          Divider(
            thickness: 0.3,
            height: kDefaultPadding,
            color: Theme.of(context).highlightColor.withValues(alpha: 0.5),
          ),
          Text(
            context.t.supportedNips.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _nipsRow(),
        ]
      ],
    );
  }

  SizedBox _nipsRow() {
    return SizedBox(
      height: 35,
      child: ListView.separated(
        itemCount: relayInfo.nips.length,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(
          width: kDefaultPadding / 4,
        ),
        itemBuilder: (context, index) {
          final n = relayInfo.nips[index];

          return Center(
            child: GestureDetector(
              onTap: () {
                openWebPage(
                  url:
                      'https://github.com/nostr-protocol/nips/blob/master/${n.padLeft(2, '0')}.md',
                );
              },
              child: Container(
                width: 35,
                height: 35,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCard
                      ? Theme.of(context).scaffoldBackgroundColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding / 4,
                  ),
                ),
                child: Text(
                  n,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Row _ownerRow(BuildContext context) {
    return Row(
      children: [
        Text(
          context.t.owner.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).highlightColor,
              ),
        ),
        const Spacer(),
        MetadataProvider(
          pubkey: relayInfo.getPubkey(),
          child: (metadata, isNip05Valid) {
            void accessProfile() {
              openProfileFastAccess(
                context: context,
                pubkey: metadata.pubkey,
              );
            }

            return GestureDetector(
              onTap: accessProfile,
              behavior: HitTestBehavior.translucent,
              child: Row(
                children: [
                  Text(
                    metadata.getName().capitalize(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: kMainColor,
                        ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  ProfilePicture3(
                    size: 25,
                    image: metadata.picture,
                    pubkey: metadata.pubkey,
                    padding: 0,
                    strokeWidth: 0,
                    strokeColor: kTransparent,
                    onClicked: accessProfile,
                  ),
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Row infoRow({
    required BuildContext context,
    required String title,
    required String text,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).highlightColor,
              ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
