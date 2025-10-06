import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first

class WotConfiguration {
  String pubkey;
  double threshold;
  bool notifications;
  bool privateMessages;
  bool postActions;

  bool get isEnabled => notifications || privateMessages || postActions;

  WotConfiguration({
    required this.pubkey,
    required this.threshold,
    required this.notifications,
    required this.privateMessages,
    required this.postActions,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pubkey': pubkey,
      'threshold': threshold,
      'notifications': notifications,
      'privateMessages': privateMessages,
      'postActions': postActions,
    };
  }

  factory WotConfiguration.fromMap(Map<String, dynamic> map) {
    return WotConfiguration(
      pubkey: map['pubkey'] as String? ?? '',
      notifications: map['notifications'] as bool? ?? false,
      privateMessages: map['privateMessages'] as bool? ?? false,
      postActions: map['postActions'] as bool? ?? false,
      threshold: map['threshold'] as double? ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory WotConfiguration.fromJson(String source) =>
      WotConfiguration.fromMap(json.decode(source) as Map<String, dynamic>);

  WotConfiguration copyWith({
    String? pubkey,
    double? threshold,
    bool? isEnabled,
    bool? notifications,
    bool? privateMessages,
    bool? postActions,
  }) {
    return WotConfiguration(
      pubkey: pubkey ?? this.pubkey,
      threshold: threshold ?? this.threshold,
      notifications: notifications ?? this.notifications,
      privateMessages: privateMessages ?? this.privateMessages,
      postActions: postActions ?? this.postActions,
    );
  }
}

String wotConfigurationsToJson(List<WotConfiguration> list) => jsonEncode(
      list
          .map(
            (e) => e.toJson(),
          )
          .toList(),
    );

List<WotConfiguration> wotConfigurationsFromJson(String json) =>
    List<WotConfiguration>.from(
      jsonDecode(json).map(
        (x) => WotConfiguration.fromJson(x),
      ),
    );
