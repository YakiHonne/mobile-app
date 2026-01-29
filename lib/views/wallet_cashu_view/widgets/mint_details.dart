import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_core_enhanced/cashu/models/mint_info.dart';

import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/content_manager/add_discover_filter.dart';
import '../../widgets/custom_app_bar.dart';

class MintDetails extends StatelessWidget {
  const MintDetails({super.key, required this.mintInfo});

  final MintInfo mintInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.details.capitalizeFirst(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(kDefaultPadding / 2),
              children: [
                Center(
                  child: CommonThumbnail(
                    image: mintInfo.iconUrl,
                    assetUrl: Images.cashu,
                    width: 100,
                    height: 100,
                    radius: 300,
                    isRound: true,
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  mintInfo.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding / 2),
                Text(
                  mintInfo.descriptionLong,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                  maxLines: 6,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding),
                _sectionTitle(context.t.contact, context),
                const SizedBox(height: kDefaultPadding / 2),
                _contact(mintInfo, context),
                const SizedBox(height: kDefaultPadding),
                _sectionTitle(context.t.details.capitalizeFirst(), context),
                const SizedBox(height: kDefaultPadding / 2),
                _details(mintInfo, context),
              ],
            ),
          ),
          if (cashuWalletManagerCubit.state.walletMints
              .contains(mintInfo.mintURL)) ...[
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
              ),
              width: double.infinity,
              child: RegularLoadingButton(
                title: context.t.syncData,
                onClicked: () {
                  HapticFeedback.mediumImpact();
                  cashuWalletManagerCubit.syncMintData(mintInfo.mintURL);
                },
                isLoading: false,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ]
        ],
      ),
    );
  }

  Row _sectionTitle(String title, BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            endIndent: kDefaultPadding / 2,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).highlightColor,
                fontWeight: FontWeight.w700,
              ),
        ),
        const Expanded(
            child: Divider(
          indent: kDefaultPadding / 2,
        )),
      ],
    );
  }

  Widget _details(MintInfo mintInfo, BuildContext context) {
    return Column(
      spacing: kDefaultPadding / 2,
      children: [
        _detailsCopiedRow(context.t.url, mintInfo.mintURL, context),
        _detailsCopiedRow(context.t.publicKey, mintInfo.pubkey, context),
        _detailsCopiedRow(context.t.version, mintInfo.version, context),
        _currencies(mintInfo, context),
        _nuts(mintInfo, context),
      ],
    );
  }

  Widget _currencies(MintInfo mintInfo, BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 2,
      children: [
        Text(
          context.t.currencies,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: kDefaultPadding / 4,
            runSpacing: kDefaultPadding / 4,
            children: mintInfo.units.map((e) {
              return Container(
                decoration: BoxDecoration(
                  color: kGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 3,
                  vertical: kDefaultPadding / 8,
                ),
                child: Text(
                  e,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: kGreen,
                      ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _nuts(MintInfo mintInfo, BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 2,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.nuts,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: kDefaultPadding / 4,
            runSpacing: kDefaultPadding / 4,
            children: mintInfo.nutsInfo.map((e) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  openWebPage(
                    url:
                        'https://github.com/cashubtc/nuts/blob/main/${e.nutNum > 9 ? e.nutNum.toString() : '0${e.nutNum}'}.md',
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(kDefaultPadding / 4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 3,
                    vertical: kDefaultPadding / 8,
                  ),
                  child: Text(
                    e.nutNum.toString(),
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _detailsCopiedRow(String title, String value, BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Clipboard.setData(ClipboardData(text: value));
        BotToastUtils.showSuccess(context.t.idCopied.capitalizeFirst());
      },
      child: Row(
        spacing: kDefaultPadding / 2,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SvgPicture.asset(
            FeatureIcons.copy,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(
              Theme.of(context).highlightColor,
              BlendMode.srcIn,
            ),
          )
        ],
      ),
    );
  }

  Widget _contact(MintInfo mintInfo, BuildContext context) {
    return Column(
        spacing: kDefaultPadding / 2,
        children: mintInfo.contact.map((e) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Clipboard.setData(ClipboardData(text: e['info'] ?? ''));
              BotToastUtils.showSuccess(context.t.idCopied.capitalizeFirst());
            },
            child: Row(
              spacing: kDefaultPadding / 2,
              children: [
                SizedBox(
                  width: 25,
                  height: 25,
                  child: getIcon(e['method'] ?? '', context),
                ),
                Expanded(
                  child: Text(
                    (e['info'] ?? '').trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SvgPicture.asset(
                  FeatureIcons.copy,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).highlightColor,
                    BlendMode.srcIn,
                  ),
                )
              ],
            ),
          );
        }).toList());
  }

  Widget getIcon(String method, BuildContext context) {
    return SvgPicture.asset(
      method.toLowerCase() == 'x' || method.toLowerCase() == 'twitter'
          ? FeatureIcons.x
          : method.toLowerCase() == 'nostr'
              ? FeatureIcons.nostr
              : FeatureIcons.message,
      width: 25,
      height: 25,
      colorFilter: ColorFilter.mode(
        Theme.of(context).primaryColorDark,
        BlendMode.srcIn,
      ),
    );
  }
}
