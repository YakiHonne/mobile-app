// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'relay_info_cubit.dart';

class RelayInfoState extends Equatable {
  final Map<String, RelayInfo> relayInfos;
  final List<RelaysCollection> collections;
  final bool refresh;
  final bool isLoading;
  final List<String> globalRelays;
  final List<String> networkRelays;
  final Map<String, List<String>> relayContacts;
  final Map<String, List<String>> relayFavored;

  const RelayInfoState({
    required this.relayInfos,
    required this.collections,
    required this.refresh,
    required this.isLoading,
    required this.globalRelays,
    required this.networkRelays,
    required this.relayContacts,
    required this.relayFavored,
  });

  @override
  List<Object> get props => [
        networkRelays,
        relayInfos,
        collections,
        refresh,
        isLoading,
        globalRelays,
        relayContacts,
        relayFavored,
      ];

  RelayInfoState copyWith({
    Map<String, RelayInfo>? relayInfos,
    List<RelaysCollection>? collections,
    bool? refresh,
    bool? isLoading,
    List<String>? globalRelays,
    List<String>? networkRelays,
    Map<String, List<String>>? relayContacts,
    Map<String, List<String>>? relayFavored,
    Map<String, List<String>>? relayFollowings,
  }) {
    return RelayInfoState(
      relayInfos: relayInfos ?? this.relayInfos,
      collections: collections ?? this.collections,
      refresh: refresh ?? this.refresh,
      isLoading: isLoading ?? this.isLoading,
      globalRelays: globalRelays ?? this.globalRelays,
      networkRelays: networkRelays ?? this.networkRelays,
      relayContacts: relayContacts ?? this.relayContacts,
      relayFavored: relayFavored ?? this.relayFavored,
    );
  }
}
