// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'properties_cubit.dart';

class PropertiesState extends Equatable {
  final bool refresh;
  final PropertiesViews propertiesViews;
  final PropertiesToggle propertiesToggle;
  final List<String> relays;
  final List<String> activeRelays;
  final List<String> onlineRelays;
  final String authPrivKey;
  final String authPubKey;
  final bool isUsingNip44;
  final bool enableAutomaticSigning;
  final bool enableGossip;
  final bool enableUsingExternalBrowser;
  final bool isUsingSigner;
  final bool enableOneTapZap;
  final bool enableOneTapReaction;
  final String defaultReaction;

  const PropertiesState({
    required this.refresh,
    required this.propertiesViews,
    required this.propertiesToggle,
    required this.relays,
    required this.activeRelays,
    required this.onlineRelays,
    required this.authPrivKey,
    required this.authPubKey,
    required this.isUsingNip44,
    required this.enableAutomaticSigning,
    required this.enableUsingExternalBrowser,
    required this.enableGossip,
    required this.isUsingSigner,
    required this.enableOneTapZap,
    required this.defaultReaction,
    required this.enableOneTapReaction,
  });

  @override
  List<Object> get props => [
        refresh,
        propertiesViews,
        propertiesToggle,
        relays,
        activeRelays,
        onlineRelays,
        authPrivKey,
        authPubKey,
        isUsingNip44,
        isUsingSigner,
        enableAutomaticSigning,
        enableUsingExternalBrowser,
        enableGossip,
        enableOneTapZap,
        enableOneTapReaction,
        defaultReaction,
      ];

  PropertiesState copyWith({
    bool? refresh,
    PropertiesViews? propertiesViews,
    PropertiesToggle? propertiesToggle,
    List<String>? relays,
    List<String>? activeRelays,
    List<String>? onlineRelays,
    String? authPrivKey,
    String? authPubKey,
    bool? isUsingNip44,
    bool? enableAutomaticSigning,
    bool? enableGossip,
    bool? enableUsingExternalBrowser,
    bool? isUsingSigner,
    bool? enableOneTapZap,
    bool? enableOneTapReaction,
    String? defaultReaction,
  }) {
    return PropertiesState(
      refresh: refresh ?? this.refresh,
      propertiesViews: propertiesViews ?? this.propertiesViews,
      propertiesToggle: propertiesToggle ?? this.propertiesToggle,
      relays: relays ?? this.relays,
      activeRelays: activeRelays ?? this.activeRelays,
      onlineRelays: onlineRelays ?? this.onlineRelays,
      authPrivKey: authPrivKey ?? this.authPrivKey,
      authPubKey: authPubKey ?? this.authPubKey,
      isUsingNip44: isUsingNip44 ?? this.isUsingNip44,
      enableAutomaticSigning:
          enableAutomaticSigning ?? this.enableAutomaticSigning,
      enableGossip: enableGossip ?? this.enableGossip,
      enableUsingExternalBrowser:
          enableUsingExternalBrowser ?? this.enableUsingExternalBrowser,
      isUsingSigner: isUsingSigner ?? this.isUsingSigner,
      enableOneTapZap: enableOneTapZap ?? this.enableOneTapZap,
      enableOneTapReaction: enableOneTapReaction ?? this.enableOneTapReaction,
      defaultReaction: defaultReaction ?? this.defaultReaction,
    );
  }
}
