// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../models/article_model.dart';
import '../../utils/utils.dart';
import '../add_content_view/related_adding_views/article_widgets/article_details.dart';
import 'data_providers.dart';
import 'profile_picture.dart';
import 'zap_split_user.dart';

class ContentZapSplits extends StatelessWidget {
  const ContentZapSplits({
    super.key,
    required this.kind,
    required this.zaps,
    required this.isZapSplitEnabled,
    required this.onToggleZapSplit,
    required this.onAddZapSplitUser,
    required this.onRemoveZapSplitUser,
    required this.onSetZapProportions,
  });

  final String kind;
  final List<ZapSplit> zaps;
  final bool isZapSplitEnabled;
  final Function() onToggleZapSplit;
  final Function(String) onAddZapSplitUser;
  final Function(String) onRemoveZapSplitUser;
  final Function(int, ZapSplit, int) onSetZapProportions;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Padding(
      padding: EdgeInsets.all(isTablet ? 10.w : 0),
      child: CustomScrollView(
        shrinkWrap: true,
        primary: false,
        slivers: [
          SliverToBoxAdapter(
            child: ArticleCheckBoxListTile(
              isEnabled: true,
              status: isZapSplitEnabled,
              text: context.t.wantToShareRevenues.capitalizeFirst(),
              onToggle: () {
                onToggleZapSplit.call();
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: kDefaultPadding,
            ),
          ),
          if (isZapSplitEnabled) ...[
            _addUser(context),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding,
              ),
            ),
            _zapSplitList(),
          ],
        ],
      ),
    );
  }

  SliverPadding _zapSplitList() {
    return SliverPadding(
      padding: const EdgeInsets.only(left: kDefaultPadding / 4),
      sliver: SliverList.separated(
        separatorBuilder: (context, index) => const SizedBox(
          height: kDefaultPadding / 2,
        ),
        itemBuilder: (context, index) {
          final zap = zaps[index];

          return ZapSplitUser(
            key: ValueKey(zap.pubkey),
            pubkey: zap.pubkey,
            percentage: getPercentage(
              zaps: zaps,
              currentZap: zap,
            ),
            onRemove: () {
              onRemoveZapSplitUser.call(zap.pubkey);
            },
            textFieldValue: zap.percentage.toString(),
            onProportionChanged: (percentage) {
              onSetZapProportions.call(index, zap, percentage);
            },
          );
        },
        itemCount: zaps.length,
      ),
    );
  }

  SliverToBoxAdapter _addUser(BuildContext context) {
    return SliverToBoxAdapter(
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.t.splitRevenuesWithUsers.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          _addUserButton(context),
        ],
      ),
    );
  }

  TextButton _addUserButton(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return ZapSplitUsers(
              currentPubkeys: zaps.map((e) => e.pubkey).toList(),
              onAddUser: (pubkey) {
                onAddZapSplitUser.call(pubkey);
              },
              onRemoveUser: (pubkey) {
                onRemoveZapSplitUser.call(pubkey);
              },
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
      label: SvgPicture.asset(
        FeatureIcons.user,
        width: 18,
        height: 18,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
        fit: BoxFit.scaleDown,
      ),
      icon: Text(
        context.t.addUser.capitalizeFirst(),
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).primaryColorDark,
            ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
      ),
    );
  }

  int getPercentage({
    required List<ZapSplit> zaps,
    required ZapSplit currentZap,
  }) {
    if (zaps.isEmpty) {
      return 0;
    }

    num total = 0;
    for (final zap in zaps) {
      total += zap.percentage;
    }

    if (total == 0) {
      return (100 / zaps.length).round();
    } else {
      return (currentZap.percentage * 100 / total).round();
    }
  }
}

class ZapSplitUser extends StatelessWidget {
  final String pubkey;
  final String textFieldValue;
  final int percentage;
  final Function(int) onProportionChanged;
  final Function() onRemove;

  const ZapSplitUser({
    super.key,
    required this.pubkey,
    required this.textFieldValue,
    required this.percentage,
    required this.onProportionChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, isNip05Valid) {
        return Row(
          children: [
            ProfilePicture3(
              size: 30,
              image: metadata.picture,
              pubkey: metadata.pubkey,
              padding: 0,
              strokeWidth: 0,
              reduceSize: true,
              strokeColor: kTransparent,
              onClicked: () {
                openProfileFastAccess(
                  context: context,
                  pubkey: metadata.pubkey,
                );
              },
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              flex: 2,
              child: Text(
                metadata.getName(),
              ),
            ),
            Text(
              '% $percentage',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Flexible(
              child: TextFormField(
                initialValue: textFieldValue,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) {
                  if (value.isEmpty) {
                    onProportionChanged.call(0);
                  } else {
                    onProportionChanged.call(int.tryParse(value) ?? 0);
                  }
                },
              ),
            ),
            IconButton(
              onPressed: () {
                onRemove.call();
              },
              icon: const Icon(
                Icons.close,
                color: kRed,
              ),
            ),
          ],
        );
      },
    );
  }
}
