import 'package:flutter/material.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../utils/utils.dart';

class CurrencySelectorButton extends StatelessWidget {
  const CurrencySelectorButton({
    super.key,
    required this.activeCurrency,
    required this.balanceInFiat,
    required this.isWalletHidden,
    required this.onCurrencyChanged,
  });

  final String activeCurrency;
  final double balanceInFiat;
  final bool isWalletHidden;
  final Function(String) onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: (context) {
        final textStyle = Theme.of(context).textTheme.labelLarge;

        return [
          ...currencies.entries.map(
            (e) {
              return PullDownMenuItem.selectable(
                onTap: () {
                  onCurrencyChanged(e.key);
                },
                title: e.key.toUpperCase(),
                selected: activeCurrency == e.key,
                iconWidget: Text(e.value),
                itemTheme: PullDownMenuItemTheme(
                  textStyle: textStyle,
                ),
              );
            },
          )
        ];
      },
      buttonBuilder: (context, showMenu) => GestureDetector(
        onTap: showMenu,
        behavior: HitTestBehavior.translucent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: kDefaultPadding / 4,
          children: [
            Text(
              '${currenciesSymbols[activeCurrency]}${isWalletHidden ? '*****' : balanceInFiat == -1 ? 'N/A' : balanceInFiat.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              activeCurrency.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
            SvgPicture.asset(
              FeatureIcons.arrowDown,
              width: 15,
              height: 15,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
