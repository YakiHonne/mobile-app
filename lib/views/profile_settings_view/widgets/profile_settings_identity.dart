import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../logic/profile_settings_cubit/profile_settings_cubit.dart';
import '../../../models/wallet_model.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../subscription_view/pricing/subscription_gate.dart';
import '../../wallet_view/widgets/wallet_options_view.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/identity_field.dart';
import '../../widgets/modal_sheet_container.dart';
import '../../widgets/modal_with_blur.dart';

/// Yaki username row. Always visible: outside a paying plan the whole
/// container is a tap target that routes to pricing, while a subscriber edits
/// or — once a name is claimed — reads it back (a username cannot be changed).
class YakiUsernameField extends HookWidget {
  const YakiUsernameField({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileSettingsCubit>();
    final controller = useTextEditingController(text: cubit.state.username);

    useEffect(
      () {
        void listener() => cubit.onUsernameChanged(controller.text);
        controller.addListener(listener);
        return () => controller.removeListener(listener);
      },
      [controller],
    );

    return BlocConsumer<ProfileSettingsCubit, ProfileSettingsState>(
      listenWhen: (p, c) => p.username != c.username,
      listener: (context, state) {
        // A fresh claim seeds the field, which is what makes it read-only.
        if (state.username.isNotEmpty && controller.text != state.username) {
          controller.text = state.username;
        }
      },
      builder: (context, state) {
        final claimed = state.username.isNotEmpty;
        final theme = Theme.of(context);
        final subscribed = isSubscribed(excludeTrial: true);

        // A claimed name is settled and unchangeable: the crown marks it as the
        // paid handle, and copying is the only action left on it.
        final field = IdentityField(
          label: context.t.yakiUsername,
          controller: controller,
          status: claimed ? AddressStatus.unchecked : state.usernameStatus,
          prefix: '$kNip05Domain/',
          hint: context.t.onboarding_name_hint,
          labelIcon: claimed ? LucideIcons.crown : null,
          trailing: claimed
              ? _CopyUsernameButton(
                  value: '$kNip05Domain/${state.username}',
                )
              : null,
        );

        // Outside the plan the row is a locked preview: the whole container is
        // a tap target that drops the user onto pricing instead of letting a
        // trial type a name it cannot claim. AbsorbPointer keeps the field's
        // own tap recognizer from swallowing the gesture.
        final row = subscribed
            ? field
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => requireSubscription(context, excludeTrial: true),
                child: AbsorbPointer(child: field),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row,
            // No description and no claim button: an available name is claimed
            // by the update-profile press, alongside the metadata.
            if (state.identityError.isNotEmpty) ...[
              const SizedBox(height: kDefaultPadding / 4),
              Text(
                state.identityError,
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.red),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Copies the claimed handle. The only action left on a settled username.
class _CopyUsernameButton extends StatelessWidget {
  const _CopyUsernameButton({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: value));
        BotToastUtils.showSuccess(context.t.textSuccesfulyCopied);
      },
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: AppIcon(
        LucideIcons.copy,
        size: 16,
        color: Theme.of(context).highlightColor,
      ),
    );
  }
}

/// Opens the Yaki NIP-05 sheet. The sheet builds outside the view's provider
/// subtree, so the cubit is passed down explicitly.
///
/// A Yaki address is part of the paid identity, so an unsubscribed user — a
/// trial included — lands on pricing instead of the sheet.
void showYakiNip05Sheet({
  required BuildContext context,
  required TextEditingController nip05,
}) {
  if (!requireSubscription(context, excludeTrial: true)) {
    return;
  }

  final cubit = context.read<ProfileSettingsCubit>();

  showAppModalSheet(
    context: context,
    backgroundColor: kTransparent,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _YakiNip05Sheet(nip05: nip05),
    ),
  );
}

class _YakiNip05Sheet extends HookWidget {
  const _YakiNip05Sheet({required this.nip05});

  /// The view's NIP-05 controller. Claiming writes the address straight into
  /// it, so the existing update button is what publishes it.
  final TextEditingController nip05;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileSettingsCubit>();
    final state = cubit.state;

    // Seeds from the account claim, falling back to the current profile address
    // when it is already a yakihonne.com one.
    final seed = state.accountNip05.isNotEmpty
        ? state.accountNip05
        : nip05.text.endsWith('@$kNip05Domain')
            ? nip05.text.split('@').first
            : '';

    final controller = useTextEditingController(text: seed);

    final status = useState(seedNip05Status(seed, state.accountNip05));

    // An owned name opens read-only; this is what unlocks it so a different one
    // can be typed, matching the Change action in the Yaki Pro sheet.
    final editing = useState(false);

    // The button's enabled state reads the field, so the sheet has to rebuild
    // as it is typed into — status changes alone lag a keystroke behind.
    useValueListenable(controller);

    return BlocBuilder<ProfileSettingsCubit, ProfileSettingsState>(
      builder: (context, state) {
        final theme = Theme.of(context);
        final owned = state.accountNip05;

        // The address is settled — the button offers Change rather than a
        // claim. Once editing starts this is false, even if the owned name is
        // typed back in, so the button stays a claim the user can complete.
        final inUse = owned.isNotEmpty &&
            !editing.value &&
            nip05.text == '$owned@$kNip05Domain' &&
            controller.text.trim() == owned;

        // Only a name the server has confirmed free — or one this account
        // already owns — can be claimed. `unchecked` covers an untouched field
        // and an illegal name, so it must not pass.
        final canClaim = !state.isClaiming &&
            controller.text.trim().isNotEmpty &&
            (status.value == AddressStatus.available ||
                status.value == AddressStatus.alreadySet);

        return ModalSheetContainer(
          // The name field sits low in the sheet, so the keyboard would cover
          // it and the claim button without this.
          padding: EdgeInsets.fromLTRB(
            kDefaultPadding,
            kDefaultPadding / 1.5,
            kDefaultPadding,
            kDefaultPadding / 1.5 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t.yakiNip05,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  CustomIconButton(
                    onClicked: () => Navigator.pop(context),
                    icon: LucideIcons.x,
                    size: 20,
                    backgroundColor: theme.cardColor,
                  ),
                ],
              ),
              const SizedBox(height: kDefaultPadding),
              if (inUse) ...[
                _LinkedAddressRow(address: '$owned@$kNip05Domain'),
                const SizedBox(height: kDefaultPadding / 2),
                Text(
                  context.t.yakiNip05AlreadySet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      editing.value = true;
                      controller.clear();
                      // The field's read-only state is derived from the status,
                      // so it must be reset here too. The row's listener runs
                      // against the pre-tap `editing` value and would otherwise
                      // settle it back to `alreadySet`, leaving the field
                      // locked.
                      status.value = AddressStatus.unchecked;
                    },
                    child: Text(context.t.yakiNip05ChangeName),
                  ),
                ),
              ] else ...[
                _Nip05NameRow(
                  controller: controller,
                  status: status,
                  ownedName: owned,
                  editing: editing,
                ),
                // Only a replacement carries a warning; a first claim has
                // nothing to overwrite.
                if (owned.isNotEmpty) ...[
                  const SizedBox(height: kDefaultPadding / 2),
                  Text(
                    context.t.yakiNip05ReplaceWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
                const SizedBox(height: kDefaultPadding),
                Row(
                  children: [
                    Expanded(
                      // Claiming needs a name the server has confirmed free —
                      // `unchecked` is an untouched or still-invalid field, so
                      // it must not pass. Faded rather than theme-disabled: the
                      // filled button paints its background regardless of the
                      // disabled state and would still read as live.
                      child: AbsorbPointer(
                        absorbing: !canClaim,
                        child: AnimatedOpacity(
                          opacity: canClaim ? 1 : 0.4,
                          duration: const Duration(milliseconds: 150),
                          child: TextButton(
                            onPressed: () async {
                              final linked = context.t.onboarding_done_desc;
                              final failed = context.t.onboarding_claim_failed;
                              final name = controller.text.trim();

                              // A name already owned needs no second claim —
                              // linking it to the profile is all that is left.
                              final claimed =
                                  status.value == AddressStatus.alreadySet &&
                                          owned == name
                                      ? '$name@$kNip05Domain'
                                      : await cubit.claimAccountNip05(name);

                              if (claimed == null) {
                                return;
                              }

                              // Publish first, then sync the controller: the
                              // field must never hold an address the profile
                              // does not carry, or the next update would
                              // revert it.
                              final published =
                                  await cubit.linkNip05ToProfile(claimed);

                              if (!published) {
                                BotToastUtils.showError(failed);
                                return;
                              }

                              nip05.text = claimed;

                              if (context.mounted) {
                                Navigator.pop(context);
                              }

                              BotToastUtils.showSuccess(linked);
                            },
                            child: state.isClaiming
                                ? const SpinKitCircle(color: kWhite, size: 16)
                                : Text(context.t.yakiNip05ClaimAndUse),
                          ),
                        ),
                      ),
                    ),
                    // Nothing to revert to on a first claim, so the second
                    // action only appears once an address is owned.
                    if (owned.isNotEmpty) ...[
                      const SizedBox(width: kDefaultPadding / 2),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isClaiming
                              ? null
                              : () {
                                  editing.value = false;
                                  // Restores the owned name and its settled
                                  // status, so the sheet reads as it did on
                                  // open.
                                  controller.text = owned;
                                  status.value = AddressStatus.alreadySet;
                                },
                          child: Text(context.t.yakiNip05Revert),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (state.identityError.isNotEmpty) ...[
                const SizedBox(height: kDefaultPadding / 4),
                Text(
                  state.identityError,
                  style:
                      theme.textTheme.labelSmall?.copyWith(color: Colors.red),
                ),
              ],
              const SizedBox(height: kDefaultPadding / 2),
            ],
          ),
        );
      },
    );
  }
}

/// The address currently on the profile, shown instead of an input when there
/// is nothing to type — the settled half of the Yaki NIP-05 sheet.
class _LinkedAddressRow extends StatelessWidget {
  const _LinkedAddressRow({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 1.5,
        vertical: kDefaultPadding / 1.5,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2 + 2),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          AppIcon(
            LucideIcons.zap,
            size: 18,
            color: theme.primaryColorDark,
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Text(
              address,
              style: theme.textTheme.bodyLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: kDefaultPadding / 2),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: kGreen,
              borderRadius: BorderRadius.circular(kDefaultPadding),
            ),
            child: Text(
              context.t.active,
              style: theme.textTheme.labelSmall?.copyWith(
                color: kWhite,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The name field inside the sheet, with its own debounced availability check.
/// Kept local because it drives a sheet-scoped value, not cubit state.
class _Nip05NameRow extends HookWidget {
  const _Nip05NameRow({
    required this.controller,
    required this.status,
    required this.ownedName,
    required this.editing,
  });

  final TextEditingController controller;
  final ValueNotifier<AddressStatus> status;
  final String ownedName;

  /// While editing, the owned name is treated like any other input. Otherwise
  /// retyping it would settle the row again and re-lock the field, leaving no
  /// way back out except closing the sheet.
  ///
  /// A notifier rather than a bool: the listener below is registered once and
  /// closes over whatever it captured, so a plain value would go stale the
  /// instant editing is toggled — which is exactly when the field must unlock.
  final ValueNotifier<bool> editing;

  @override
  Widget build(BuildContext context) {
    final seq = useRef(0);

    // The debounce and the request outlive the sheet: closing it disposes
    // `status` while a check is still in flight, and writing to a disposed
    // notifier throws. Neither the seq nor the text guard catches that — the
    // sheet closing changes neither.
    final alive = useRef(true);
    useEffect(() => () => alive.value = false, const []);

    useEffect(
      () {
        void listener() {
          final name = controller.text.trim();

          // The account's own name always reads as taken by the server, but
          // there is nothing left to claim for it.
          if (name.isEmpty) {
            status.value = AddressStatus.unchecked;
            return;
          }
          if (name == ownedName && !editing.value) {
            status.value = AddressStatus.alreadySet;
            return;
          }

          status.value = AddressStatus.checking;
          final current = ++seq.value;

          Future.delayed(const Duration(milliseconds: 500), () async {
            if (!alive.value ||
                current != seq.value ||
                controller.text.trim() != name) {
              return;
            }

            final result =
                await HttpFunctionsRepository.checkNip05Availability(name);

            if (!alive.value ||
                current != seq.value ||
                controller.text.trim() != name) {
              return;
            }

            status.value = addressStatusOf(result);
          });
        }

        controller.addListener(listener);
        return () => controller.removeListener(listener);
      },
      // Not keyed on `editing`: it is a notifier read live inside the listener,
      // so re-registering on every toggle would only risk the listener missing
      // the very edit that triggered it.
      [controller, ownedName],
    );

    return IdentityField(
      label: context.t.onboarding_nostr_address,
      controller: controller,
      status: status.value,
      suffix: '@$kNip05Domain',
      hint: context.t.onboarding_name_hint,
    );
  }
}

/// Lets the user pick a lightning address from a connected wallet instead of
/// typing one. Only fills the field — publishing stays with the update button.
void showWalletAddressSheet({
  required BuildContext context,
  required TextEditingController lud16,
}) {
  final addresses = context.read<ProfileSettingsCubit>().walletAddresses;

  showAppModalSheet(
    context: context,
    backgroundColor: kTransparent,
    builder: (_) => _WalletAddressSheet(addresses: addresses, lud16: lud16),
  );
}

class _WalletAddressSheet extends StatelessWidget {
  const _WalletAddressSheet({required this.addresses, required this.lud16});

  final List<WalletModel> addresses;
  final TextEditingController lud16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModalSheetContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding / 1.5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: ModalBottomSheetHandle()),
          Text(
            context.t.onboarding_lightning_address,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: kDefaultPadding / 2,
              ),
              child: Text(
                context.t.noWalletCanBeFound.capitalizeFirst(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            )
          else
            ...addresses.map(
              (wallet) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox.square(
                  dimension: 20,
                  child: SvgPicture.asset(
                    wallet is AlbyConnectModel
                        ? FeatureIcons.alby
                        : FeatureIcons.nwc,
                  ),
                ),
                title: Text(
                  wallet.lud16,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: lud16.text == wallet.lud16
                    ? const AppIcon(
                        LucideIcons.check,
                        size: 16,
                        color: kGreen,
                      )
                    : null,
                onTap: () {
                  lud16.text = wallet.lud16;
                  Navigator.pop(context);
                },
              ),
            ),
          const SizedBox(height: kDefaultPadding / 2),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                // The sheet closes first, so the dialog needs a context that
                // outlives it — the navigator's own.
                final navigator = Navigator.of(context);
                navigator.pop();
                showBlurredModal(
                  context: navigator.context,
                  view: const WalletOptions(),
                );
              },
              child: Text(context.t.addWallet.capitalizeFirst()),
            ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
        ],
      ),
    );
  }
}
