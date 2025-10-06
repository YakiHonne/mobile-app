class LightningInvoice {
  const LightningInvoice({
    required this.id,
    required this.invoice,
    required this.paymentHash,
    required this.amountSats,
    required this.recipientPubkey,
    required this.currentPubkey,
    this.eventId,
    this.aTag,
    this.comment,
    required this.createdAt,
    this.paidAt,
    this.zapReceiptId,
  });

  final String id;
  final String invoice;
  final String paymentHash;
  final int amountSats;
  final String recipientPubkey;
  final String currentPubkey;
  final String? eventId;
  final String? aTag;
  final String? comment;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? zapReceiptId;

  MapEntry<String, bool>? toSubmitZap() {
    if (eventId != null || aTag != null) {
      return MapEntry(
        eventId ?? aTag!,
        aTag != null,
      );
    }

    return null;
  }
}
