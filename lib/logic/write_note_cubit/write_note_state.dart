// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_note_cubit.dart';

/// Lifecycle of the paid-note payment verification + publish flow, rendered
/// inline in [PaidNoteProcess].
enum PaidNoteVerification {
  /// Sheet open — no verification running yet (fresh flow, invoice not requested).
  idle,

  /// Status check / SSE stream open, waiting for the payment to settle.
  verifying,

  /// The stream ended without a `paid` event — the manual confirm fallback
  /// is the only visible action.
  awaitingConfirm,

  /// Payment confirmed — the note is being broadcast.
  publishing,

  /// Note published successfully.
  published,
}

class WriteNoteState extends Equatable {
  final List<String> medias;
  final List<Map<String, String>> imetas;
  final BaseEventModel? quotedContent;
  final bool isQuotedContentAvailable;
  final bool isMention;
  final bool isQuote;
  final PaidNoteVerification verification;

  /// Last SSE event received from the payment stream: `waiting`, `paid` or
  /// `unpaid`. Empty when no stream data arrived yet.
  final String paymentStatus;

  const WriteNoteState({
    required this.medias,
    required this.imetas,
    this.quotedContent,
    required this.isQuotedContentAvailable,
    required this.isMention,
    required this.isQuote,
    this.verification = PaidNoteVerification.idle,
    this.paymentStatus = '',
  });

  @override
  List<Object> get props => [
        medias,
        imetas,
        isQuotedContentAvailable,
        isMention,
        isQuote,
        verification,
        paymentStatus,
      ];

  WriteNoteState copyWith({
    List<String>? medias,
    List<Map<String, String>>? imetas,
    BaseEventModel? quotedContent,
    bool? isQuotedContentAvailable,
    bool? isMention,
    bool? isQuote,
    PaidNoteVerification? verification,
    String? paymentStatus,
  }) {
    return WriteNoteState(
      medias: medias ?? this.medias,
      imetas: imetas ?? this.imetas,
      quotedContent: quotedContent ?? this.quotedContent,
      isQuotedContentAvailable:
          isQuotedContentAvailable ?? this.isQuotedContentAvailable,
      isMention: isMention ?? this.isMention,
      isQuote: isQuote ?? this.isQuote,
      verification: verification ?? this.verification,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
