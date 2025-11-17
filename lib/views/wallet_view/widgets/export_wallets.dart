// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../models/wallet_model.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

class ExportWalletOnCreation extends StatelessWidget {
  const ExportWalletOnCreation({super.key, required this.wallet});

  final NostrWalletConnectModel wallet;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: isTablet ? 50.w : double.infinity,
      margin: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        spacing: kDefaultPadding / 2,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t.walletConnectionString,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            context.t.walletConnectionStringDesc,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Column(
            children: [
              Row(
                spacing: kDefaultPadding / 4,
                children: [
                  _export(context),
                  _copy(context),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => YNavigator.pop(context),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                    side: const BorderSide(
                      color: kRed,
                    ),
                  ),
                  child: Text(
                    context.t.cancel.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: kRed,
                        ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Expanded _copy(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: Theme.of(context).cardColor,
        ),
        onPressed: () {
          Clipboard.setData(
            ClipboardData(text: wallet.connectionString),
          );

          BotToastUtils.showSuccess(
            context.t.nwcCopied.capitalize(),
          );
        },
        label: SvgPicture.asset(
          FeatureIcons.copy,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        icon: Text(
          context.t.copy.capitalizeFirst(),
        ),
      ),
    );
  }

  Expanded _export(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: () async {
          final res = await exportWalletToUserDirectory(
            {
              '': [wallet]
            },
          );

          if (res == ResultType.done && context.mounted) {
            YNavigator.pop(context);
          } else if (res == ResultType.noAppToOpen) {
            BotToastUtils.showError(context.t.noApp);
          }
        },
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: Theme.of(context).cardColor,
        ),
        label: SvgPicture.asset(
          FeatureIcons.export,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        icon: Text(context.t.export),
      ),
    );
  }
}

class ExportWalletOnLoginOut extends StatelessWidget {
  const ExportWalletOnLoginOut({
    super.key,
    required this.wallets,
    required this.onLogout,
  });

  final Map<String, List<NostrWalletConnectModel>> wallets;
  final Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return Container(
      width: isTablet ? 50.w : double.infinity,
      margin: const EdgeInsets.all(kDefaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(kDefaultPadding),
      ),
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        spacing: kDefaultPadding / 2,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.t.wallets.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            context.t.exportWalletsDesc,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Column(
            children: [
              _exportLogout(context),
              _logout(context),
              _cancel(context),
            ],
          )
        ],
      ),
    );
  }

  SizedBox _cancel(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => YNavigator.pop(context),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          side: const BorderSide(
            color: kRed,
          ),
        ),
        child: Text(
          context.t.cancel.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: kRed,
              ),
        ),
      ),
    );
  }

  SizedBox _logout(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: Theme.of(context).cardColor,
        ),
        onPressed: onLogout,
        label: SvgPicture.asset(
          FeatureIcons.log,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        icon: Text(
          context.t.logout.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).primaryColorDark,
              ),
        ),
      ),
    );
  }

  SizedBox _exportLogout(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          final res = await exportWalletToUserDirectory(
            wallets,
          );

          if (res == ResultType.done && context.mounted) {
            YNavigator.pop(context);
            onLogout.call();
          } else if (res == ResultType.noAppToOpen) {
            BotToastUtils.showError(context.t.noApp);
          }
        },
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: Theme.of(context).cardColor,
        ),
        label: SvgPicture.asset(
          FeatureIcons.export,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
        icon: Text(
          context.t.exportAndLogout,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).primaryColorDark,
              ),
        ),
      ),
    );
  }
}
