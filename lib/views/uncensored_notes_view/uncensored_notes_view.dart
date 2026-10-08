// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:numeral/numeral.dart';

import '../../logic/uncensored_notes_cubit/uncensored_notes_cubit.dart';
import '../../utils/utils.dart';
import '../widgets/app_icon.dart';
import '../widgets/custom_icon_buttons.dart';

class CommunityWalletContainer extends StatelessWidget {
  const CommunityWalletContainer({
    super.key,
    required this.isMainView,
    required this.onClicked,
  });

  final bool isMainView;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        top: kDefaultPadding / 2,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding),
          color: Theme.of(context).cardColor,
        ),
        child: Stack(
          children: [
            Positioned(
              left: -20,
              child: Transform.rotate(
                angle: 0.7,
                child: AppIcon(
                  FeatureIcons.reward,
                  size: 100,
                  color: Theme.of(context)
                      .primaryColorDark
                      .withValues(alpha: 0.15),
                ),
              ),
            ),
            _communityWallet(context),
          ],
        ),
      ),
    );
  }

  Padding _communityWallet(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.communityWallet.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).primaryColorDark,
                      ),
                ),
                _balance(),
              ],
            ),
          ),
          CustomIconButton(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            icon: isMainView ? FeatureIcons.reward : FeatureIcons.refresh,
            onClicked: onClicked,
            size: 22,
          ),
        ],
      ),
    );
  }

  BlocBuilder<UncensoredNotesCubit, UncensoredNotesState> _balance() {
    return BlocBuilder<UncensoredNotesCubit, UncensoredNotesState>(
      builder: (context, state) {
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: state.balance.numeral(),
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              TextSpan(
                text: ' Sats.',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                      fontWeight: FontWeight.w600,
                    ),
              )
            ],
          ),
        );
      },
    );
  }
}
