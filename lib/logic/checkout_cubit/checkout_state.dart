part of 'checkout_cubit.dart';

class CheckoutState extends Equatable {
  const CheckoutState({
    this.phase = CheckoutPhase.paying,
    this.error = '',
    this.notice = '',
    this.invoice,
  });

  final CheckoutPhase phase;
  final String error;
  final String notice;

  /// Set when a Lightning invoice is ready; the screen opens the sheet on it.
  final String? invoice;

  CheckoutState copyWith({
    CheckoutPhase? phase,
    String? error,
    String? notice,
    String? invoice,
    bool? clearInvoice,
  }) {
    return CheckoutState(
      phase: phase ?? this.phase,
      error: error ?? this.error,
      notice: notice ?? this.notice,
      invoice: (clearInvoice ?? false) ? null : invoice ?? this.invoice,
    );
  }

  @override
  List<Object?> get props => [phase, error, notice, invoice];
}
