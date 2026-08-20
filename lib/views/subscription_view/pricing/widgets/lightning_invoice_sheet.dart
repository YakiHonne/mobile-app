// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../repositories/http_functions_repository.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/modal_sheet_container.dart';

enum LnPayStatus { waiting, paid, error }

class LightningInvoiceSheet extends StatefulWidget {
  const LightningInvoiceSheet({
    super.key,
    required this.invoice,
    required this.planName,
    required this.sats,
    required this.pubkey,
    required this.onPaid,
  });

  final String invoice;
  final String planName;
  final String sats;
  final String pubkey;
  final VoidCallback onPaid;

  @override
  State<LightningInvoiceSheet> createState() => _LightningInvoiceSheetState();
}

class _LightningInvoiceSheetState extends State<LightningInvoiceSheet> {
  LnPayStatus _status = LnPayStatus.waiting;
  StreamSubscription<Map<String, dynamic>>? _sub;
  DateTime? _renewsAt;

  @override
  void initState() {
    super.initState();
    _sub = HttpFunctionsRepository.subscriptionLightningPaymentStream(widget.pubkey)
        .listen(
          (data) {
            if (data['status'] == 'paid') {
              final nextSub = data['next_subscription'];
              _renewsAt = nextSub != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                      (nextSub as num).toInt() * 1000,
                    )
                  : null;
              setState(() => _status = LnPayStatus.paid);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                widget.onPaid();
              }
              });
            }
          },
          onError: (_) {
            if (_status != LnPayStatus.paid && mounted) {
              setState(() => _status = LnPayStatus.error);
            }
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _copyInvoice() {
    Clipboard.setData(ClipboardData(text: widget.invoice));
    BotToastUtils.showSuccess(context.t.pricing_invoice_copied);
  }

  @override
  Widget build(BuildContext context) {
    return ModalSheetContainer(
      padding: const EdgeInsets.fromLTRB(kDefaultPadding, 0, kDefaultPadding, kDefaultPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalBottomSheetHandle(),
          if (_status == LnPayStatus.paid)
            _PaidState(planName: widget.planName, renewsAt: _renewsAt)
          else
            _WaitingState(
              invoice: widget.invoice,
              planName: widget.planName,
              sats: widget.sats,
              status: _status,
              onCopy: _copyInvoice,
              onCancel: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _PaidState extends StatelessWidget {
  const _PaidState({required this.planName, required this.renewsAt});
  final String planName;
  final DateTime? renewsAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final renewsStr = renewsAt != null
        ? ' ${context.t.pricing_renews(date: '${renewsAt!.day}/${renewsAt!.month}/${renewsAt!.year}')}'
        : '';

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(LucideIcons.check, color: primary, size: 36),
        ),
        const SizedBox(height: kDefaultPadding),
        Text(
          context.t.pricing_payment_confirmed,
          style: theme.textTheme.titleLarge?.copyWith(color: primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: kDefaultPadding / 4),
        Text(
          context.t.pricing_plan_activated(plan: planName + renewsStr),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.pricing_refreshing,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: kDefaultPadding),
      ],
    );
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({
    required this.invoice,
    required this.planName,
    required this.sats,
    required this.status,
    required this.onCopy,
    required this.onCancel,
  });

  final String invoice;
  final String planName;
  final String sats;
  final LnPayStatus status;
  final VoidCallback onCopy;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final truncated = invoice.length > 48 ? '${invoice.substring(0, 48)}…' : invoice;

    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(LucideIcons.zap, color: primary, size: 26),
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.pricing_pay_lightning,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: kDefaultPadding / 4),
        RichText(
          text: TextSpan(
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            children: [
              TextSpan(text: '${context.t.pricing_plan_label(plan: planName)}  ·  '),
              TextSpan(text: '$sats sats', style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        Container(
          padding: const EdgeInsets.all(kDefaultPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kDefaultPadding),
            boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 4))],
          ),
          child: QrImageView(data: invoice, size: 220),
        ),
        const SizedBox(height: kDefaultPadding),
        GestureDetector(
          onTap: onCopy,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    truncated,
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: theme.hintColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: kDefaultPadding / 2),
                Text(
                  context.t.copy,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding, vertical: kDefaultPadding / 2),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SpinKitCircle(color: primary, size: 14),
              const SizedBox(width: kDefaultPadding / 2),
              Text(
                context.t.pricing_waiting,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
              ),
            ],
          ),
        ),
        if (status == LnPayStatus.error) ...[
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.pricing_connection_lost,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: kDefaultPadding),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: onCancel, child: Text(context.t.pricing_cancel)),
        ),
      ],
    );
  }
}
