// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../common/common_regex.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../repositories/nostr_functions_repository.dart';
import '../../../utils/utils.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/fluid_scaffold.dart';
import '../../widgets/identity_field.dart';

const _kNip05Domain = kNip05Domain;
const _kWalletDomain = kWalletDomain;

/// The three independently claimable rows. Each one debounces and checks on its
/// own, so editing one never re-queries the others.
enum _Row { name, nostr, lightning }

const _kDebounce = Duration(milliseconds: 500);

/// Identity setup: one name claims a username, a NIP-05 and a lightning
/// address. Each derived field stays individually editable, and the claim
/// publishes a kind-0 only when the user agrees to overwrite what is there.
class IdentityOnboardingView extends StatefulWidget {
  const IdentityOnboardingView({
    super.key,
    required this.onDone,
    this.onSkip,
  });

  final VoidCallback onDone;
  final VoidCallback? onSkip;

  @override
  State<IdentityOnboardingView> createState() => _IdentityOnboardingViewState();
}

class _IdentityOnboardingViewState extends State<IdentityOnboardingView> {
  final _nameCtrl = TextEditingController();
  final _nostrCtrl = TextEditingController();
  final _lnCtrl = TextEditingController();

  /// Once hand-edited, a derived field stops following the name field.
  bool _nostrDetached = false;
  bool _lnDetached = false;

  bool _saving = false;

  /// Set once every claim has landed — swaps the form for the summary.
  bool _claimed = false;
  String _error = '';

  AddressStatus _nameStatus = AddressStatus.unchecked;
  AddressStatus _nostrStatus = AddressStatus.unchecked;
  AddressStatus _lnStatus = AddressStatus.unchecked;

  /// Existing kind-0 values that a claim would replace. Empty when there is
  /// nothing to overwrite, which is what hides the checkbox.
  String _existingNip05 = '';
  String _existingLud16 = '';
  bool _overrideMetadata = true;

  final Map<_Row, Timer> _debounce = {};

  /// Per-row sequence numbers: a slow response for an older value must not
  /// overwrite a newer one.
  final Map<_Row, int> _seq = {};

  bool get _checking =>
      [_nameStatus, _nostrStatus, _lnStatus].contains(AddressStatus.checking);

  String get _name => _nameCtrl.text.trim();
  String get _nostrName => _nostrCtrl.text.trim();
  String get _lnName => _lnCtrl.text.trim();

  String get _nostrAddress =>
      _nostrName.isEmpty ? '' : '$_nostrName@$_kNip05Domain';
  String get _lnAddress => _lnName.isEmpty ? '' : '$_lnName@$_kWalletDomain';

  bool get _hasConflict =>
      _existingNip05.isNotEmpty || _existingLud16.isNotEmpty;

  bool get _nameValid => isValidUsername(_name);

  bool get _canClaim =>
      !_saving &&
      !_checking &&
      _nameValid &&
      _nostrName.isNotEmpty &&
      [_nameStatus, _nostrStatus, _lnStatus].every(
        (s) =>
            s != AddressStatus.unchecked &&
            s != AddressStatus.checking &&
            s != AddressStatus.taken,
      );

  @override
  void initState() {
    super.initState();
    final meta = nostrRepository.currentMetadata;
    final account = subscriptionCubit.state.subscriptionStatus;

    _existingNip05 = meta.nip05;
    _existingLud16 = meta.lud16;

    // The account is the authority for what is already claimed; kind-0 only
    // says what the profile advertises, and the two can disagree. Falls back to
    // a sanitized display name when the account holds nothing yet.
    final claimed = [
      account?.username ?? '',
      account?.nip05.name ?? '',
    ].firstWhere((s) => s.isNotEmpty, orElse: () => '');
    _nameCtrl.text = claimed.isNotEmpty ? claimed : _sanitize(meta.name);

    final ownedNip05 = account?.nip05.name ?? '';
    _nostrCtrl.text = ownedNip05.isNotEmpty ? ownedNip05 : _name;

    // A non-empty list means the account already has an address; the screen
    // claims one, so the first is the one this row represents.
    final ownedWallet = account?.wallets.firstOrNull ?? '';
    _lnCtrl.text = ownedWallet.isNotEmpty ? ownedWallet : _name;

    _nameCtrl.addListener(_onNameChanged);
    _nostrCtrl.addListener(_onNostrEdited);
    _lnCtrl.addListener(_onLnEdited);

    // Seed each row that has a value; rows already owned come back alreadySet.
    // Deferred a frame because _check calls setState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final row in _Row.values) {
        if (_valueOf(row).isNotEmpty) {
          _check(row);
        }
      }
    });
  }

  /// Best-effort conversion of a display name into a legal username.
  String _sanitize(String s) {
    final stripped = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
    return stripped.substring(0, stripped.length.clamp(0, 30));
  }

  @override
  void dispose() {
    for (final t in _debounce.values) {
      t.cancel();
    }
    _nameCtrl.dispose();
    _nostrCtrl.dispose();
    _lnCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _error = '';
      if (_nameStatus != AddressStatus.alreadySet) {
        _nameStatus = AddressStatus.unchecked;
      }
      // An attached row mirrors the username, so it needs rechecking too.
      if (!_nostrDetached && _nostrStatus != AddressStatus.alreadySet) {
        _nostrCtrl.text = _name;
        _nostrStatus = AddressStatus.unchecked;
      }
      if (!_lnDetached && _lnStatus != AddressStatus.alreadySet) {
        _lnCtrl.text = _name;
        _lnStatus = AddressStatus.unchecked;
      }
    });

    _schedule(_Row.name);
    if (!_nostrDetached) {
      _schedule(_Row.nostr);
    }
    if (!_lnDetached) {
      _schedule(_Row.lightning);
    }
  }

  void _onNostrEdited() {
    if (_nostrName == _name) {
      return;
    }
    setState(() {
      _nostrDetached = true;
      _error = '';
      if (_nostrStatus != AddressStatus.alreadySet) {
        _nostrStatus = AddressStatus.unchecked;
      }
    });
    _schedule(_Row.nostr);
  }

  void _onLnEdited() {
    if (_lnName == _name) {
      return;
    }
    setState(() {
      _lnDetached = true;
      _error = '';
      if (_lnStatus != AddressStatus.alreadySet) {
        _lnStatus = AddressStatus.unchecked;
      }
    });
    _schedule(_Row.lightning);
  }

  /// Restarts one row's debounce. Only that row is re-queried, so editing the
  /// NIP-05 field never costs a username or wallet lookup.
  void _schedule(_Row row) {
    _debounce[row]?.cancel();

    if (_valueOf(row).isEmpty) {
      // Nothing to look up; drop any in-flight result for this row.
      _seq[row] = (_seq[row] ?? 0) + 1;
      setState(() => _setStatus(row, _blankStatus(row)));
      return;
    }

    if (row == _Row.name && !_nameValid) {
      _seq[row] = (_seq[row] ?? 0) + 1;
      setState(() => _setStatus(row, AddressStatus.unchecked));
      return;
    }

    _debounce[row] = Timer(_kDebounce, () => _check(row));
  }

  String _valueOf(_Row row) => switch (row) {
        _Row.name => _name,
        _Row.nostr => _nostrName,
        _Row.lightning => _lnName,
      };

  /// A blank username or NIP-05 is simply unchecked; a blank lightning field is
  /// a deliberate opt-out.
  AddressStatus _blankStatus(_Row row) =>
      row == _Row.lightning ? AddressStatus.skipped : AddressStatus.unchecked;

  /// `setState(_setStatus)` for the claim path, where every call sits after an
  /// await and the screen may already be gone.
  void _markStatus(_Row row, AddressStatus s) {
    if (!mounted) {
      return;
    }
    setState(() => _setStatus(row, s));
  }

  void _setStatus(_Row row, AddressStatus s) {
    switch (row) {
      case _Row.name:
        _nameStatus = s;
      case _Row.nostr:
        _nostrStatus = s;
      case _Row.lightning:
        _lnStatus = s;
    }
  }

  Future<void> _check(_Row row) async {
    final name = _valueOf(row);
    if (name.isEmpty) {
      return;
    }

    final seq = (_seq[row] ?? 0) + 1;
    _seq[row] = seq;

    setState(() => _setStatus(row, AddressStatus.checking));

    final result = await switch (row) {
      _Row.name => HttpFunctionsRepository.checkUsernameAvailability(name),
      _Row.nostr => HttpFunctionsRepository.checkNip05Availability(name),
      _Row.lightning => HttpFunctionsRepository.checkWalletAvailability(name),
    };

    // Discard a superseded check, and one whose field moved on while in flight.
    if (!mounted || seq != _seq[row] || _valueOf(row) != name) {
      return;
    }

    setState(() {
      _setStatus(row, addressStatusOf(result));
      if (!result.available && !result.owned) {
        _error = result.reason ?? '';
      } else if (_error == (result.reason ?? '')) {
        _error = '';
      }
    });
  }

  Future<void> _claim() async {
    if (!_canClaim) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = '';
    });

    final pubkey = currentSigner?.getPublicKey() ?? '';

    try {
      if (_nameStatus != AddressStatus.alreadySet) {
        final reason = await HttpFunctionsRepository.claimUsername(_name);
        if (reason != null) {
          _fail(() => _nameStatus = AddressStatus.taken, reason);
          return;
        }
        _markStatus(_Row.name, AddressStatus.alreadySet);
      }

      // Wallet before NIP-05: it is the one claim with an external side effect
      // that cannot be undone, so it should not run after a partial failure.
      var lud16 = '';
      if (_lnStatus == AddressStatus.alreadySet) {
        lud16 = _lnAddress;
      } else if (_lnName.isNotEmpty) {
        final wallet =
            await HttpFunctionsRepository.createLightningWallet(_lnName);

        if (wallet.nwc == null) {
          // Only a refusal means the name is unusable. An unreadable 2xx leaves
          // the row alone — sending the user off to rename a name the server
          // never objected to would be a dead end.
          if (wallet.rejected) {
            _fail(
              () => _lnStatus = AddressStatus.taken,
              wallet.reason ?? t.onboarding_wallet_taken,
            );
          } else {
            _fail(() {}, t.onboarding_wallet_unreadable);
          }
          return;
        }

        lud16 = _lud16FromNwc(wallet.nwc!) ?? wallet.lightningAddress!;

        // addNwc parses the same URI into a NostrWalletConnectModel and saves
        // it to the wallet list the wallet UI reads. It does not publish a
        // kind-0, so there is no race with _publishKind0 below.
        await walletManagerCubit.addNwc(wallet.nwc!);
        _markStatus(_Row.lightning, AddressStatus.alreadySet);
      }

      if (_nostrStatus != AddressStatus.alreadySet) {
        final reason = await HttpFunctionsRepository.claimNip05(
          name: _nostrName,
          pubkey: pubkey,
        );
        if (reason != null) {
          _fail(() => _nostrStatus = AddressStatus.taken, reason);
          return;
        }
        _markStatus(_Row.nostr, AddressStatus.alreadySet);
      }

      // Unchecking leaves the Nostr profile exactly as it was; the names are
      // still claimed on the account, they are just not advertised in kind-0.
      if (_overrideMetadata || !_hasConflict) {
        await _publishKind0(lud16);
      }

      await HttpFunctionsRepository.markOnboarded();

      // Pulls username/nip05/wallets/onboarded back into state, so a second
      // visit to this screen seeds from the claims instead of offering them
      // again. Not awaited: the summary below does not read it.
      unawaited(subscriptionCubit.refreshStatus());

      if (mounted) {
        setState(() => _claimed = true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  /// The address the wallet actually zaps from, read off the NWC URI — that is
  /// the one `addNwc` stores on the model, so publishing the server's separate
  /// string instead could advertise an address the saved wallet does not use.
  ///
  /// Null when the URI is malformed or carries no `lud16`, which leaves the
  /// caller on the server's value. The wallet exists either way at this point,
  /// so a parse failure must not read as a failed claim.
  String? _lud16FromNwc(String uri) {
    try {
      final lud16 = Uri.parse(uri).queryParameters['lud16'] ?? '';
      return lud16.isEmpty ? null : lud16;
    } catch (_) {
      return null;
    }
  }

  /// Stops the save, marking one row as the blocker. Rows claimed before this
  /// point keep their `alreadySet` status so a retry skips them.
  ///
  /// Nothing blocks a back-out mid-claim, so the screen can be gone by the time
  /// a claim call returns. The server state is safe either way — `already_set`
  /// maps to success, which is what makes the retry idempotent.
  void _fail(VoidCallback markRow, String? reason) {
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      markRow();
      _error = reason ?? t.onboarding_claim_failed;
    });
  }

  /// kind-0 is replaceable, so this rewrites the whole content — copyWith on
  /// the current metadata is what preserves name/picture/banner/about/website.
  ///
  /// `lud06` is rewritten alongside `lud16`, matching `linkWallet` and
  /// `updateMetadata`: every path in the app that writes a lightning address
  /// derives the LNURL from it, and leaving the old one behind would advertise
  /// a profile whose two zap fields point at different wallets.
  Future<void> _publishKind0(String lud16) async {
    final current = nostrRepository.currentMetadata;

    final hasNewLud16 = lud16.isNotEmpty && emailRegExp.hasMatch(lud16);
    final lud06 = hasNewLud16 ? Zap.getLnurlFromLud16(lud16) : null;

    final metadata = current.copyWith(
      nip05: _nostrAddress.isNotEmpty ? _nostrAddress : current.nip05,
      lud16: hasNewLud16 ? lud16 : current.lud16,
      lud06: lud06 ?? current.lud06,
    );

    final kind0Event = await Event.genEvent(
      content: metadata.toJson(),
      kind: EventKind.METADATA,
      signer: currentSigner,
      tags: [],
    );

    if (kind0Event == null) {
      return;
    }

    final isSuccessful = await NostrFunctionsRepository.sendEvent(
      event: kind0Event,
      relays: currentUserRelayList.urls.toList(),
      setProgress: false,
    );

    if (!isSuccessful) {
      return;
    }

    nostrRepository.currentMetadata = Metadata.fromEvent(kind0Event)!;
    nostrRepository.setCurrentSignerState(currentSigner);
    await metadataCubit.saveMetadata(nostrRepository.currentMetadata);
  }

  @override
  Widget build(BuildContext context) {
    return FluidScaffold(
      title: context.t.onboarding_title,
      // The form is gone once the names are claimed, so back means done.
      onBackClicked: _claimed ? widget.onDone : null,
      body: SafeArea(
        top: false,
        child: _claimed
            ? _success(context)
            : Column(
                children: [
                  Expanded(child: _fields(context)),
                  _actions(context),
                ],
              ),
      ),
    );
  }

  Widget _success(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              kDefaultPadding,
              fluidScaffoldTopInset(context) + kDefaultPadding,
              kDefaultPadding,
              kDefaultPadding,
            ),
            children: [
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen.withValues(alpha: 0.14),
                    border: Border.all(color: kGreen.withValues(alpha: 0.4)),
                  ),
                  child: const AppIcon(
                    LucideIcons.check,
                    size: 34,
                    color: kGreen,
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              Text(
                context.t.onboarding_done_title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: kDefaultPadding / 3),
              Text(
                context.t.onboarding_done_desc,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: kDefaultPadding),
              _ClaimedRow(value: '$_kNip05Domain/$_name'),
              const SizedBox(height: kDefaultPadding / 2),
              _ClaimedRow(value: _nostrAddress),
              if (_lnName.isNotEmpty) ...[
                const SizedBox(height: kDefaultPadding / 2),
                _ClaimedRow(value: _lnAddress),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kDefaultPadding,
            kDefaultPadding / 2,
            kDefaultPadding,
            kDefaultPadding / 2,
          ),
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: widget.onDone,
              child: Text(context.t.onboarding_done_cta),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fields(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        kDefaultPadding,
        fluidScaffoldTopInset(context) + kDefaultPadding / 2,
        kDefaultPadding,
        kDefaultPadding,
      ),
      children: [
        Text(
          context.t.onboarding_eyebrow.toUpperCase(),
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: kMainColor,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.onboarding_heading,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.onboarding_desc,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: kDefaultPadding),
        IdentityField(
          label: context.t.onboarding_name_label,
          controller: _nameCtrl,
          status: _nameStatus,
          prefix: '$_kNip05Domain/',
          hint: context.t.onboarding_name_hint,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        IdentityField(
          label: context.t.onboarding_nostr_address,
          controller: _nostrCtrl,
          status: _nostrStatus,
          suffix: '@$_kNip05Domain',
          hint: context.t.onboarding_name_hint,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        IdentityField(
          label: context.t.onboarding_lightning_address,
          controller: _lnCtrl,
          status: _lnStatus,
          suffix: '@$_kWalletDomain',
          hint: context.t.onboarding_name_hint,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          // A name that fails the pattern disables the button, so say why
          // rather than leaving it inert with no explanation.
          _name.isNotEmpty && !_nameValid
              ? context.t.onboarding_username_invalid
              : context.t.onboarding_username_rules,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color:
                _name.isNotEmpty && !_nameValid ? Colors.red : theme.hintColor,
          ),
        ),
        if (_hasConflict) ...[
          const SizedBox(height: kDefaultPadding / 2),
          _OverrideCheckbox(
            value: _overrideMetadata,
            label: _overrideLabel(context),
            description: context.t.onboarding_override_desc(
              current: [_existingNip05, _existingLud16]
                  .where((e) => e.isNotEmpty)
                  .join(' · '),
            ),
            onChanged: (v) => setState(() => _overrideMetadata = v),
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.red),
          ),
        ],
      ],
    );
  }

  String _overrideLabel(BuildContext context) {
    if (_existingNip05.isNotEmpty && _existingLud16.isNotEmpty) {
      return context.t.onboarding_override_both;
    }
    return _existingNip05.isNotEmpty
        ? context.t.onboarding_override_nip05
        : context.t.onboarding_override_lud16;
  }

  Widget _actions(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        kDefaultPadding,
        kDefaultPadding / 2,
        kDefaultPadding,
        kDefaultPadding / 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: _saving
                ? Padding(
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    child: Center(
                      child: SpinKitCircle(
                        color: theme.primaryColor,
                        size: 28,
                      ),
                    ),
                  )
                // Faded rather than themed-disabled: the theme paints the fill
                // regardless of the disabled state, so a disabled button would
                // still read as live.
                : IgnorePointer(
                    ignoring: !_canClaim,
                    child: AnimatedOpacity(
                      opacity: _canClaim ? 1 : 0.4,
                      duration: const Duration(milliseconds: 150),
                      child: TextButton(
                        onPressed: _claim,
                        child: Text(context.t.onboarding_claim),
                      ),
                    ),
                  ),
          ),
          if (widget.onSkip != null && !_saving) ...[
            const SizedBox(height: kDefaultPadding / 4),
            GestureDetector(
              onTap: () {
                HttpFunctionsRepository.markOnboarded();
                widget.onSkip!();
              },
              behavior: HitTestBehavior.translucent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding / 2,
                  vertical: kDefaultPadding / 4,
                ),
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  context.t.onboarding_maybe_later,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: theme.primaryColorDark,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClaimedRow extends StatelessWidget {
  const _ClaimedRow({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2 + 2,
        vertical: kDefaultPadding / 2 + 2,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2 + 2),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          const AppIcon(LucideIcons.check, size: 15, color: kGreen),
          const SizedBox(width: kDefaultPadding / 2),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverrideCheckbox extends StatelessWidget {
  const _OverrideCheckbox({
    required this.value,
    required this.label,
    required this.description,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final String description;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(kDefaultPadding / 2),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: value,
                visualDensity: VisualDensity.compact,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
