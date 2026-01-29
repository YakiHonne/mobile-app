import 'dart:convert';

import 'package:nostr_core_enhanced/cashu/models/proof.dart';
import 'package:nostr_core_enhanced/nostr/event.dart';

class NutZap {
  NutZap({
    required this.id,
    required this.senderPubkey,
    required this.recipientPubkey,
    required this.amount,
    required this.unit,
    required this.mintUrl,
    required this.memo,
    required this.proofs,
    required this.createdAt,
    required this.event,
    this.isClaimed = false,
  });
  factory NutZap.fromEvent(Event event) {
    String unit = 'sat';
    String mintUrl = '';
    String recipientPubkey = '';
    final List<Proof> proofs = [];

    for (final tag in event.tags) {
      if (tag.length < 2) {
        continue;
      }
      if (tag[0] == 'unit') {
        unit = tag[1];
      } else if (tag[0] == 'u') {
        mintUrl = tag[1];
      } else if (tag[0] == 'p') {
        recipientPubkey = tag[1];
      } else if (tag[0] == 'proof') {
        try {
          proofs.add(Proof.fromServerJson(jsonDecode(tag[1])));
        } catch (_) {}
      }
    }

    final int totalAmount = proofs.fold(0, (sum, p) => sum + p.amountNum);

    return NutZap(
      id: event.id,
      senderPubkey: event.pubkey,
      recipientPubkey: recipientPubkey,
      amount: totalAmount,
      unit: unit,
      mintUrl: mintUrl,
      memo: event.content,
      proofs: proofs,
      createdAt: event.createdAt,
      event: event,
    );
  }
  final String id;
  final String senderPubkey;
  final String recipientPubkey;
  final int amount;
  final String unit;
  final String mintUrl;
  final String memo;
  final List<Proof> proofs;
  final int createdAt;
  final Event event;
  final bool isClaimed;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_pubkey': senderPubkey,
      'recipient_pubkey': recipientPubkey,
      'amount': amount,
      'unit': unit,
      'mint_url': mintUrl,
      'memo': memo,
      'proofs': proofs.map((p) => p.toJson()).toList(),
      'created_at': createdAt,
      'event': event.toJson(),
      'is_claimed': isClaimed,
    };
  }

  NutZap copyWith({
    bool? isClaimed,
  }) {
    return NutZap(
      id: id,
      senderPubkey: senderPubkey,
      recipientPubkey: recipientPubkey,
      amount: amount,
      unit: unit,
      mintUrl: mintUrl,
      memo: memo,
      proofs: proofs,
      createdAt: createdAt,
      event: event,
      isClaimed: isClaimed ?? this.isClaimed,
    );
  }
}
