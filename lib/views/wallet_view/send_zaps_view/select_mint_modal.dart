import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/cashu_wallet_manager_cubit/cashu_wallet_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/dotted_container.dart';

/// Simple modal to select a Cashu mint for payments
class SelectMintModal extends StatelessWidget {
  const SelectMintModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashuWalletManagerCubit, CashuWalletManagerState>(
      builder: (context, state) {
        final activeMints = state.walletMints
            .map((mintUrl) => state.mints[mintUrl])
            .where((mint) => mint != null)
            .toList();

        return Material(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(kDefaultPadding),
            topRight: Radius.circular(kDefaultPadding),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(kDefaultPadding),
                topRight: Radius.circular(kDefaultPadding),
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ModalBottomSheetHandle(),
                Text(
                  context.t.selectMint,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: kDefaultPadding),
                ...activeMints.map((mint) {
                  final isActive = state.activeMint == mint!.mintURL;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: kDefaultPadding / 2),
                    child: GestureDetector(
                      onTap: () {
                        context
                            .read<CashuWalletManagerCubit>()
                            .setActiveMint(mint.mintURL);
                        YNavigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(kDefaultPadding / 2),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(kDefaultPadding / 2),
                          border: Border.all(
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).dividerColor,
                            width: isActive ? 1 : 0.5,
                          ),
                          color: Theme.of(context).cardColor,
                        ),
                        child: Row(
                          spacing: kDefaultPadding / 2,
                          children: [
                            CommonThumbnail(
                              image: mint.info?.iconUrl ?? '',
                              assetUrl: Images.cashu,
                              width: 40,
                              height: 40,
                              radius: kDefaultPadding / 2,
                              isRound: true,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          mint.info?.name ?? mint.mintURL,
                                          maxLines: 1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (mint.balance > 0) ...[
                                        DotContainer(
                                          color:
                                              Theme.of(context).highlightColor,
                                        ),
                                        Text(
                                          '${mint.balance} sats',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ]
                                    ],
                                  ),
                                  if (mint.info?.description != null)
                                    Text(
                                      mint.info!.description,
                                      maxLines: 1,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .highlightColor,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (isActive)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: kBottomNavigationBarHeight),
              ],
            ),
          ),
        );
      },
    );
  }
}
