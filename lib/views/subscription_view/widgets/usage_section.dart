// ignore_for_file: use_build_context_synchronously

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../logic/points_management_cubit/points_management_cubit.dart';
import '../../../logic/subscription_cubit/subscription_cubit.dart';
import '../../../models/points_system_models.dart';
import '../../../models/subscription_models.dart';
import '../../../models/wallet_model.dart';
import '../../../repositories/http_functions_repository.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/theme/custom/buttons_theme.dart';
import '../../../utils/utils.dart';
import '../../widgets/buttons_containers_widgets.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/fluid_blur_container.dart';
import '../../widgets/fluid_sheet.dart';
import '../../widgets/modal_sheet_container.dart';
import '../pricing/pricing_screen.dart';

const double _kGroupRadius = 12.0;

enum _CodeRequestBlock { notLoggedIn, insufficientPoints, limitReached }

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(kDefaultPadding, kDefaultPadding,
          kDefaultPadding, kDefaultPadding / 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.hintColor,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class UsageSection extends StatefulWidget {
  const UsageSection({super.key});

  @override
  State<UsageSection> createState() => _UsageSectionState();
}

class _UsageSectionState extends State<UsageSection> {
  List<PointsRedeemCode> _redeemCodes = [];
  PointsConfig? _pointsConfig;
  bool _codesLoading = false;
  bool _requesting = false;
  String? _redeemingCode;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    setState(() => _codesLoading = true);
    try {
      final codes = await HttpFunctionsRepository.getRedeemCodes();
      PointsConfig? config;
      try {
        config = await HttpFunctionsRepository.getPointsConfig();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _redeemCodes = codes;
          _pointsConfig = config;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _codesLoading = false);
      }
    }
  }

  /// Whether the user may create a new redeem code: system-logged-in, enough
  /// consumable points to cover the code cost, and within the outstanding-code
  /// limits (`limit` per period, `monthly_limit` per month) from `/points/config`.
  /// Why the user currently cannot create a redeem code, or null if they can.
  _CodeRequestBlock? _requestBlock(PointsManagementState pointsState) {
    final config = _pointsConfig;
    if (config == null) {
      return _CodeRequestBlock.insufficientPoints;
    }
    if (!pointsState.isSystemLoggedIn) {
      return _CodeRequestBlock.notLoggedIn;
    }
    if (pointsState.consumablePoints < config.redeemCodeCost) {
      return _CodeRequestBlock.insufficientPoints;
    }

    final now = DateTime.now();
    final periodStart =
        now.subtract(Duration(days: config.redeemCodePeriodDays));
    final monthStart = DateTime(now.year, now.month);
    var inPeriod = 0, inMonth = 0;
    for (final c in _redeemCodes) {
      if (c.status || c.reservedAt == 0) {
        continue;
      }
      final dt = DateTime.fromMillisecondsSinceEpoch(c.reservedAt * 1000);
      if (dt.isAfter(periodStart)) {
        inPeriod++;
      }
      if (dt.isAfter(monthStart)) {
        inMonth++;
      }
    }
    if (inPeriod >= config.redeemCodeLimit) {
      return _CodeRequestBlock.limitReached;
    }
    if (inMonth >= config.redeemCodeMonthlyLimit) {
      return _CodeRequestBlock.limitReached;
    }
    return null;
  }

  bool _canRequestCode(PointsManagementState pointsState) =>
      _requestBlock(pointsState) == null;

  void _onDeniedRequest(PointsManagementState pointsState) {
    final message = switch (_requestBlock(pointsState)) {
      _CodeRequestBlock.notLoggedIn => context.t.points_request_login,
      _CodeRequestBlock.insufficientPoints =>
        context.t.points_insufficient_code,
      _CodeRequestBlock.limitReached => context.t.points_request_limit,
      null => '',
    };
    if (message.isNotEmpty) {
      BotToastUtils.showInformation(message);
    }
  }

  Future<void> _requestCode() async {
    setState(() => _requesting = true);
    try {
      await HttpFunctionsRepository.requestRedeemCode();
      if (mounted) {
        BotToastUtils.showSuccess(context.t.points_request_success);
      }
      await _loadCodes();
    } on DioException catch (e) {
      if (mounted) {
        BotToastUtils.showError(
          (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
              context.t.points_request_error,
        );
      }
    } catch (_) {
      if (mounted) {
        BotToastUtils.showError(context.t.points_request_error);
      }
    } finally {
      if (mounted) {
        setState(() => _requesting = false);
      }
    }
  }

  Future<void> _redeemCode(PointsRedeemCode code) async {
    final lightningAddress = await showAppModalSheet<String>(
      context: context,
      builder: (_) => _RedeemCodeSheet(code: code),
    );
    if (lightningAddress == null || lightningAddress.isEmpty) {
      return;
    }
    setState(() => _redeemingCode = code.code);
    try {
      await HttpFunctionsRepository.redeemPointsCode(
        code: code.code,
        lightningAddress: lightningAddress,
      );
      if (mounted) {
        BotToastUtils.showSuccess(context.t.points_redeem_success);
      }
      await _loadCodes();
    } on DioException catch (e) {
      if (mounted) {
        BotToastUtils.showError(
          (e.response?.data as Map<String, dynamic>?)?['message'] as String? ??
              context.t.points_redeem_error,
        );
      }
    } catch (_) {
      if (mounted) {
        BotToastUtils.showError(context.t.points_redeem_error);
      }
    } finally {
      if (mounted) {
        setState(() => _redeemingCode = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      bloc: subscriptionCubit,
      buildWhen: (p, c) =>
          p.usageData != c.usageData ||
          p.usageRefreshing != c.usageRefreshing ||
          p.subscriptionStatus != c.subscriptionStatus,
      builder: (context, state) {
        final s = state.subscriptionStatus;
        final showRedeemCodes = s != null && s.active && !s.inTrial;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUsageList(context, state),
            if (showRedeemCodes) ...[
              _SectionLabel(context.t.points_redeem_codes),
              BlocBuilder<PointsManagementCubit, PointsManagementState>(
                bloc: pointsManagementCubit,
                buildWhen: (p, c) =>
                    p.consumablePoints != c.consumablePoints ||
                    p.isSystemLoggedIn != c.isSystemLoggedIn,
                builder: (context, pointsState) => _RedeemCodesSection(
                  codes: _redeemCodes,
                  loading: _codesLoading,
                  requesting: _requesting,
                  redeemingCode: _redeemingCode,
                  canRequest: _canRequestCode(pointsState),
                  onRequest: _requestCode,
                  onDenied: () => _onDeniedRequest(pointsState),
                  onRedeem: _redeemCode,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildUsageList(BuildContext context, SubscriptionState state) {
    if (state.usageRefreshing && state.usageData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 2),
          child: SpinKitThreeBounce(
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
      );
    }

    final items = state.usageData?.items ?? [];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding * 2),
          child: Text(
            context.t.sub_usage_load_error,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).hintColor),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(kDefaultPadding),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: kDefaultPadding / 2),
      itemBuilder: (context, i) => _UsageRow(
        item: items[i],
        onUpgrade: () => YNavigator.pushPage(
          context,
          (_) => const PricingScreen(),
        ),
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.item, required this.onUpgrade});

  final UsageItem item;
  final VoidCallback onUpgrade;

  String _fmtResetIn(BuildContext context) {
    if (item.resetAt == 0) {
      return '';
    }
    final dt = DateTime.fromMillisecondsSinceEpoch(item.resetAt * 1000);
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative || diff.inMinutes < 1) {
      return context.t.sub_usage_resets_soon;
    }
    if (diff.inDays >= 1) {
      return context.t.sub_usage_resets_in(time: '${diff.inDays}d');
    }
    if (diff.inHours >= 1) {
      return context.t.sub_usage_resets_in(time: '${diff.inHours}h');
    }
    return context.t.sub_usage_resets_in(time: '${diff.inMinutes}m');
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).hintColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return FluidCardContainer(
      borderRadius: kDefaultPadding / 2,
      padding: const EdgeInsets.all(kDefaultPadding * 0.75),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (item.isUnlimited)
                _Badge(
                  label: context.t.sub_usage_unlimited,
                  color: Colors.green,
                )
              else if (item.isLocked)
                _Badge(
                  label: context.t.sub_usage_locked,
                  color: Colors.red.shade400,
                ),
            ],
          ),
          if (item.isLocked) ...[
            const SizedBox(height: kDefaultPadding / 2),
            GestureDetector(
              onTap: onUpgrade,
              child: Text(
                context.t.sub_usage_upgrade_prompt,
                style: textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  decoration: TextDecoration.underline,
                  decorationColor: primaryColor,
                ),
              ),
            ),
          ] else if (!item.isUnlimited) ...[
            const SizedBox(height: kDefaultPadding / 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (item.percentage / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: hintColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  item.percentage >= 90 ? Colors.orange : primaryColor,
                ),
              ),
            ),
            const SizedBox(height: kDefaultPadding / 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item.percentage.toStringAsFixed(0)}%',
                  style: textTheme.labelSmall?.copyWith(color: hintColor),
                ),
                if (item.resetAt != 0)
                  Text(
                    _fmtResetIn(context),
                    style: textTheme.labelSmall?.copyWith(color: hintColor),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

// ── Redeem Code Sheet ────────────────────────────────────────────────────────

class _RedeemCodeSheet extends StatefulWidget {
  const _RedeemCodeSheet({required this.code});
  final PointsRedeemCode code;

  @override
  State<_RedeemCodeSheet> createState() => _RedeemCodeSheetState();
}

class _RedeemCodeSheetState extends State<_RedeemCodeSheet> {
  final _controller = TextEditingController();
  WalletModel? _selectedWallet;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectWallet(WalletModel wallet) {
    setState(() {
      if (_selectedWallet?.id == wallet.id) {
        _selectedWallet = null;
        _controller.clear();
      } else {
        _selectedWallet = wallet;
        _controller.text = wallet.lud16;
      }
    });
  }

  void _confirm() {
    final address = _controller.text.trim();
    if (address.isEmpty) {
      return;
    }
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final wallets = walletManagerCubit.state.wallets.values
        .where((w) => w.lud16.isNotEmpty)
        .toList();

    return ModalSheetContainer(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: kDefaultPadding / 2),
              child: Center(child: ModalBottomSheetHandle()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kDefaultPadding,
                kDefaultPadding / 2,
                kDefaultPadding,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.points_redeem_action,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding / 4),
                  Text(
                    context.t.points_enter_lightning,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            if (wallets.isNotEmpty) ...[
              const SizedBox(height: kDefaultPadding),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                child: Text(
                  context.t.lightningAddress.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: kDefaultPadding / 4),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < wallets.length; i++) ...[
                        _WalletTile(
                          wallet: wallets[i],
                          isSelected: _selectedWallet?.id == wallets[i].id,
                          onTap: () => _selectWallet(wallets[i]),
                        ),
                        if (i < wallets.length - 1)
                          Divider(
                            height: 0.5,
                            thickness: 0.5,
                            indent: kDefaultPadding,
                            color: theme.dividerColor,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: kDefaultPadding / 2,
                  horizontal: kDefaultPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: theme.dividerColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: kDefaultPadding / 2,
                      ),
                      child: Text(
                        context.t.or,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: theme.dividerColor,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: kDefaultPadding),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) {
                  if (_selectedWallet != null &&
                      _controller.text != _selectedWallet!.lud16) {
                    setState(() => _selectedWallet = null);
                  }
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'user@wallet.com',
                  prefixIcon: Icon(
                    LucideIcons.zap,
                    color: theme.hintColor,
                    size: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kDefaultPadding,
                kDefaultPadding,
                kDefaultPadding,
                kDefaultPadding,
              ),
              child: Row(
                spacing: kDefaultPadding / 2,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.t.cancel.capitalizeFirst()),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      onPressed: _confirm,
                      child: Text(context.t.points_redeem_action),
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

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.wallet,
    required this.isSelected,
    required this.onTap,
  });

  final WalletModel wallet;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding * 0.75,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.12)
                    : theme.scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.5)
                      : theme.dividerColor,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Icon(
                LucideIcons.wallet,
                size: 18,
                color: isSelected ? theme.primaryColor : theme.hintColor,
              ),
            ),
            const SizedBox(width: kDefaultPadding / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wallet.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    wallet.lud16,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                LucideIcons.circleCheck,
                size: 18,
                color: theme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Redeem Codes Section ─────────────────────────────────────────────────────

class _RedeemCodesSection extends StatelessWidget {
  const _RedeemCodesSection({
    required this.codes,
    required this.loading,
    required this.requesting,
    required this.redeemingCode,
    required this.canRequest,
    required this.onRequest,
    required this.onDenied,
    required this.onRedeem,
  });

  final List<PointsRedeemCode> codes;
  final bool loading;
  final bool requesting;
  final String? redeemingCode;
  final bool canRequest;
  final VoidCallback onRequest;
  final VoidCallback onDenied;
  final ValueChanged<PointsRedeemCode> onRedeem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = !canRequest;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: requesting
                  ? null
                  : disabled
                      ? onDenied
                      : onRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    disabled ? theme.dividerColor : theme.primaryColor,
                side: BorderSide(
                  color: disabled ? theme.dividerColor : theme.primaryColor,
                  width: 1.5,
                ),
                shape: const StadiumBorder(),
              ),
              icon: requesting
                  ? SpinKitCircle(color: theme.primaryColor, size: 14)
                  : const Icon(LucideIcons.plus, size: 18),
              label: Text(context.t.points_request_code),
            ),
          ),
          if (loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: kDefaultPadding),
              child: Center(
                  child:
                      SpinKitCircle(color: theme.primaryColorDark, size: 32)),
            )
          else if (codes.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
              child: Text(
                context.t.points_no_codes,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: kDefaultPadding / 2),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(_kGroupRadius),
                border: Border.all(color: theme.dividerColor, width: 0.5),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < codes.length; i++) ...[
                    _RedeemCodeRow(
                      code: codes[i],
                      isRedeeming: redeemingCode == codes[i].code,
                      onRedeem: () => onRedeem(codes[i]),
                    ),
                    if (i < codes.length - 1)
                      Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: kDefaultPadding,
                        color: theme.dividerColor,
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: kDefaultPadding / 2),
        ],
      ),
    );
  }
}

class _RedeemCodeRow extends StatelessWidget {
  const _RedeemCodeRow({
    required this.code,
    required this.isRedeeming,
    required this.onRedeem,
  });

  final PointsRedeemCode code;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  /// "1000" → "1k", "1500" → "1.5k", "250" → "250".
  String _fmtSats(int amount) {
    if (amount >= 1000) {
      final k = amount / 1000;
      final s =
          k == k.roundToDouble() ? k.round().toString() : k.toStringAsFixed(1);
      return '${s}k';
    }
    return '$amount';
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code.code));
    BotToastUtils.showSuccess(context.t.textSuccesfulyCopied);
  }

  Widget _useButton(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: onRedeem,
      style: TbuttonsTheme.solidTextButtonStyle(Theme.of(context).primaryColor),
      child: Text(
        context.t.points_code_use,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRedeemed = code.status;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding * 0.75,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code.code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'worth ${_fmtSats(code.amount)} sats. '
                  '${isRedeemed ? context.t.points_code_used : context.t.points_code_unused}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isRedeemed ? Colors.green : theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
          if (!isRedeemed)
            isRedeeming
                ? SpinKitCircle(color: theme.primaryColor, size: 16)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _useButton(context),
                      const SizedBox(width: kDefaultPadding / 4),
                      AppIconButton(
                        icon: LucideIcons.copy,
                        iconSize: 16,
                        onClicked: () => _copyCode(context),
                      ),
                    ],
                  ),
        ],
      ),
    );
  }
}
