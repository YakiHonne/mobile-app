// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:typed_data';

class BlossomFetchResult {
  const BlossomFetchResult({
    required this.success,
    this.data,
    this.mimeType,
    this.error,
    this.sourceUrl,
  });

  final bool success;
  final Uint8List? data;
  final String? mimeType;
  final String? error;
  final String? sourceUrl;
}

class BlossomInfo {
  const BlossomInfo({
    required this.hash,
    this.extension,
    this.baseUrl,
  });

  final String hash;
  final String? extension;
  final String? baseUrl;
}

class FetchResponse {
  const FetchResponse({
    required this.success,
    this.data,
    this.mimeType,
    this.error,
  });

  final bool success;
  final Uint8List? data;
  final String? mimeType;
  final String? error;
}

class ServerConfig {
  const ServerConfig({
    required this.baseUrl,
    required this.uploadPath,
  });
  final String baseUrl;
  final String uploadPath;

  String get fullUrl => '$baseUrl$uploadPath';
}

String mediaManagerToJson(List<MediaManagerItem> list) => jsonEncode(
      list
          .map(
            (e) => e.toJson(),
          )
          .toList(),
    );

List<MediaManagerItem> mediaManagerFromJson(String json) =>
    List<MediaManagerItem>.from(
      jsonDecode(json).map(
        (x) => MediaManagerItem.fromJson(x),
      ),
    );

class MediaManagerItem {
  String pubkey;
  String activeRegularServer;
  bool isBlossomEnabled;
  bool isMirroringEnabled;

  MediaManagerItem({
    required this.pubkey,
    required this.activeRegularServer,
    required this.isBlossomEnabled,
    required this.isMirroringEnabled,
  });

  MediaManagerItem copyWith({
    String? pubkey,
    String? activeRegularServer,
    bool? isBlossomEnabled,
    bool? isMirroringEnabled,
  }) {
    return MediaManagerItem(
      pubkey: pubkey ?? this.pubkey,
      activeRegularServer: activeRegularServer ?? this.activeRegularServer,
      isBlossomEnabled: isBlossomEnabled ?? this.isBlossomEnabled,
      isMirroringEnabled: isMirroringEnabled ?? this.isMirroringEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'activeRegularServer': activeRegularServer,
      'isBlossomEnabled': isBlossomEnabled,
      'isMirroringEnabled': isMirroringEnabled,
    };
  }

  factory MediaManagerItem.fromMap(Map<String, dynamic> map) {
    return MediaManagerItem(
      pubkey: map['pubkey'] as String,
      activeRegularServer: map['activeRegularServer'] as String,
      isBlossomEnabled: map['isBlossomEnabled'] as bool,
      isMirroringEnabled: map['isMirroringEnabled'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory MediaManagerItem.fromJson(String source) =>
      MediaManagerItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
