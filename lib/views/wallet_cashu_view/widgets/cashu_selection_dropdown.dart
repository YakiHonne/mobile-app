import 'package:flutter/material.dart';

import '../../../utils/utils.dart';
import '../../widgets/common_thumbnail.dart';

class CashuDropdownItem<T> {
  CashuDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.assetIcon,
    this.balance,
  });
  final T value;
  final String label;
  final String? icon;
  final String? assetIcon;
  final int? balance;
}

class CashuSelectionDropdown<T> extends StatelessWidget {
  const CashuSelectionDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });
  final T? value;
  final List<CashuDropdownItem<T>> items;
  final String hint;
  final void Function(T? value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.8,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(
            hint,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          dropdownColor: Theme.of(context).cardColor,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                spacing: kDefaultPadding / 3,
                children: [
                  CommonThumbnail(
                    image: item.icon ?? '',
                    assetUrl: item.assetIcon,
                    width: 25,
                    height: 25,
                    isRound: true,
                  ),
                  Expanded(
                    child: Text(
                      item.label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (item.balance != null) ...[
                    Text(
                      '${item.balance} sats',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
