// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names
import 'dart:convert';

import 'package:equatable/equatable.dart';

const NostrWalletConnectKind = 1;
const AlbyConnectKind = 2;

class WalletModel extends Equatable {
  final String id;
  final int kind;
  final String lud16;

  const WalletModel({
    required this.id,
    required this.kind,
    required this.lud16,
  });

  @override
  List<Object?> get props => [
        id,
        kind,
        lud16,
      ];
}

class AlbyConnectModel extends WalletModel {
  final String accessToken;
  final String refreshToken;
  final int expiry;
  final int createdAt;

  const AlbyConnectModel({
    required super.id,
    required super.kind,
    required super.lud16,
    required this.accessToken,
    required this.refreshToken,
    required this.expiry,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        kind,
        accessToken,
        refreshToken,
        expiry,
        createdAt,
        lud16,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'kind': kind,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiry': expiry,
      'createdAt': createdAt,
      'lud16': lud16,
    };
  }

  factory AlbyConnectModel.fromMap(Map<String, dynamic> map) {
    return AlbyConnectModel(
      id: map['id'] as String,
      kind: map['kind'] as int,
      lud16: map['lud16'] as String,
      accessToken: map['accessToken'] as String,
      refreshToken: map['refreshToken'] as String,
      expiry: map['expiry'] as int,
      createdAt: map['createdAt'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory AlbyConnectModel.fromJson(String source) =>
      AlbyConnectModel.fromMap(json.decode(source) as Map<String, dynamic>);

  AlbyConnectModel copyWith({
    String? accessToken,
    String? refreshToken,
    int? expiry,
    int? createAt,
  }) {
    return AlbyConnectModel(
      id: id,
      kind: kind,
      lud16: lud16,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiry: expiry ?? this.expiry,
      createdAt: createAt ?? createdAt,
    );
  }
}

class NostrWalletConnectModel extends WalletModel {
  final String connectionString;
  final String relay;
  final String secret;
  final String walletPubkey;
  final List<String> permissions;

  const NostrWalletConnectModel({
    required super.id,
    required super.kind,
    required super.lud16,
    required this.connectionString,
    required this.relay,
    required this.secret,
    required this.walletPubkey,
    required this.permissions,
  });

  @override
  List<Object?> get props => [
        id,
        kind,
        connectionString,
        relay,
        secret,
        walletPubkey,
        lud16,
        permissions,
      ];

  NostrWalletConnectModel copyWith({
    String? connectionString,
    String? relay,
    String? secret,
    String? walletPubkey,
    String? lud16,
    List<String>? permissions,
  }) {
    return NostrWalletConnectModel(
      id: id,
      kind: kind,
      connectionString: connectionString ?? this.connectionString,
      relay: relay ?? this.relay,
      secret: secret ?? this.secret,
      walletPubkey: walletPubkey ?? this.walletPubkey,
      lud16: lud16 ?? this.lud16,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'kind': kind,
      'connectionString': connectionString,
      'relay': relay,
      'secret': secret,
      'walletPubkey': walletPubkey,
      'lud16': lud16,
      'permissions': permissions,
    };
  }

  factory NostrWalletConnectModel.fromMap(Map<String, dynamic> map) {
    return NostrWalletConnectModel(
      id: map['id'] as String,
      kind: map['kind'] as int,
      connectionString: map['connectionString'] as String,
      relay: map['relay'] as String,
      secret: map['secret'] as String,
      walletPubkey: map['walletPubkey'] as String,
      lud16: map['lud16'] as String,
      permissions: List<String>.from(map['permissions'] as List),
    );
  }

  String toJson() => json.encode(toMap());

  factory NostrWalletConnectModel.fromJson(String source) =>
      NostrWalletConnectModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

extension WalletModelName on WalletModel {
  String get name {
    if (this is AlbyConnectModel) {
      return 'Alby';
    } else if (this is NostrWalletConnectModel) {
      return 'NWC (${(this as NostrWalletConnectModel).lud16.isNotEmpty ? (this as NostrWalletConnectModel).lud16 : '...'})';
    }
    return 'Wallet';
  }
}
