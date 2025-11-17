// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../models/wallet_model.dart';
import '../../utils/utils.dart';
import 'buttons_containers_widgets.dart';
import 'response_snackbar.dart';

class CustomDropDown extends StatelessWidget {
  const CustomDropDown({
    super.key,
    required this.list,
    this.onChanged,
    this.formKey,
    this.isDisabled,
    this.validator,
    this.capitalize = false,
    required this.defaultValue,
  });

  final List<String> list;
  final Function(String?)? onChanged;
  final String defaultValue;
  final bool capitalize;
  final GlobalKey<FormFieldState>? formKey;
  final bool? isDisabled;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      key: formKey,
      validator: validator,
      initialValue: defaultValue,
      isExpanded: true,
      menuMaxHeight: 50.h,
      style: Theme.of(context).textTheme.bodyMedium,
      dropdownColor: Theme.of(context).cardColor,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 20,
      ),
      items: list
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(
                capitalize ? e.capitalizeFirst() : e,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: isDisabled == null ? onChanged : null,
    );
  }
}

class WalletsCustomDropDown extends HookWidget {
  const WalletsCustomDropDown({
    super.key,
    required this.list,
    required this.defaultValue,
    required this.formKey,
    required this.onDelete,
    required this.onChanged,
    this.color,
  });

  final List<WalletModel> list;
  final String defaultValue;
  final GlobalKey<FormFieldState> formKey;
  final Function(String) onDelete;
  final Function(String?) onChanged;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isMenuOpen = useState(false);

    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        key: formKey,
        value: defaultValue,
        isExpanded: true,
        buttonStyleData: ButtonStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: color ?? Theme.of(context).cardColor,
          ),
          padding: const EdgeInsets.only(right: kDefaultPadding / 2),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: 50.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: color ?? Theme.of(context).cardColor,
          ),
        ),
        iconStyleData: const IconStyleData(
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
          ),
        ),
        onMenuStateChange: (isOpen) async {
          isMenuOpen.value = isOpen;
        },
        items: list
            .map(
              (e) => _dropDownItem(e, isMenuOpen),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  DropdownMenuItem<String> _dropDownItem(
      WalletModel e, ValueNotifier<bool> isMenuOpen) {
    return DropdownMenuItem(
      value: e.id,
      child: StatefulBuilder(
        builder: (context, menuSetState) => Row(
          children: [
            if (defaultValue == e.id) ...[
              const DotContainer(
                color: kGreen,
                isNotMarging: true,
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
            ],
            Expanded(
              child: Text(
                e.lud16,
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: defaultValue == e.id ? kGreen : null,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMenuOpen.value) _deleteWallet(isMenuOpen, context, e),
          ],
        ),
      ),
    );
  }

  IconButton _deleteWallet(
      ValueNotifier<bool> isMenuOpen, BuildContext context, WalletModel e) {
    return IconButton(
      onPressed: () {
        if (isMenuOpen.value) {
          showCupertinoDeletionDialogue(
            context: context,
            title: context.t.deleteWallet,
            description: context.t.deleteWalletDesc,
            buttonText: context.t.delete.capitalizeFirst(),
            toBeCopied:
                e is NostrWalletConnectModel ? e.connectionString : null,
            onDelete: () {
              onDelete.call(e.id);
            },
          );
        }
      },
      style: IconButton.styleFrom(
        visualDensity: const VisualDensity(
          horizontal: -4,
          vertical: -4,
        ),
      ),
      icon: const Icon(
        Icons.remove,
        color: kRed,
        size: 20,
      ),
    );
  }
}
