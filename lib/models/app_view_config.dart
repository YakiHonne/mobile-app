import 'dart:convert';

import '../utils/utils.dart';
import 'relays_feed.dart';

class AppViewConfig {
  const AppViewConfig({
    required this.selectedLeadingSourceType,
    required this.selectedLeadingSource,
    required this.selectedMediaSourceType,
    required this.selectedMediaSource,
    required this.selectedArticlesSourceType,
    required this.selectedArticlesSource,
  });

  factory AppViewConfig.initial() => const AppViewConfig(
        selectedLeadingSourceType: AppContentSource.community,
        selectedLeadingSource: MapEntry('recent', 'recent'),
        selectedMediaSourceType: AppContentSource.community,
        selectedMediaSource: MapEntry('recent', 'recent'),
        selectedArticlesSourceType: AppContentSource.community,
        selectedArticlesSource: MapEntry('top', 'top'),
      );

  factory AppViewConfig.fromMap(Map<String, dynamic> json) {
    MapEntry<String, dynamic> parseSelectedSource(dynamic source) {
      if (source == null) {
        return const MapEntry('', '');
      }

      if (source is Map) {
        final key = source.keys.first;
        final value = source.values.first;

        if (value is Map) {
          return MapEntry(
            key,
            UserRelaySet.fromMap(Map<String, dynamic>.from(value)),
          );
        }

        return MapEntry(key, value);
      }
      return const MapEntry('', '');
    }

    return AppViewConfig(
      selectedLeadingSourceType: AppContentSource.values.firstWhere(
        (e) => e.name == (json['selectedLeadingSourceType'] ?? ''),
        orElse: () => AppContentSource.community,
      ),
      selectedLeadingSource: parseSelectedSource(json['selectedLeadingSource']),
      selectedMediaSourceType: AppContentSource.values.firstWhere(
        (e) => e.name == (json['selectedMediaSourceType'] ?? ''),
        orElse: () => AppContentSource.community,
      ),
      selectedMediaSource: parseSelectedSource(json['selectedMediaSource']),
      selectedArticlesSourceType: AppContentSource.values.firstWhere(
        (e) => e.name == (json['selectedArticlesSourceType'] ?? ''),
        orElse: () => AppContentSource.community,
      ),
      selectedArticlesSource:
          parseSelectedSource(json['selectedArticlesSource']),
    );
  }

  final AppContentSource selectedLeadingSourceType;
  final MapEntry<String, dynamic> selectedLeadingSource;

  final AppContentSource selectedMediaSourceType;
  final MapEntry<String, dynamic> selectedMediaSource;

  final AppContentSource selectedArticlesSourceType;
  final MapEntry<String, dynamic> selectedArticlesSource;

  MapEntry<String, dynamic> getMediaSource() {
    if (selectedMediaSourceType == AppContentSource.community) {
      return selectedMediaSource;
    } else if (selectedMediaSourceType == AppContentSource.relay) {
      final exist = relayInfoCubit.state.relayFeeds.favoriteRelays
          .contains(selectedMediaSource.key);
      return exist ? selectedMediaSource : const MapEntry('recent', 'recent');
    } else {
      final exist = relayInfoCubit.state.userRelaySets.keys
          .contains(selectedMediaSource.key);
      return exist ? selectedMediaSource : const MapEntry('recent', 'recent');
    }
  }

  MapEntry<String, dynamic> getArticlesSource() {
    if (selectedArticlesSourceType == AppContentSource.community) {
      return selectedArticlesSource;
    } else if (selectedArticlesSourceType == AppContentSource.relay) {
      final exist = relayInfoCubit.state.relayFeeds.favoriteRelays
          .contains(selectedArticlesSource.key);
      return exist ? selectedArticlesSource : const MapEntry('top', 'top');
    } else {
      final exist = relayInfoCubit.state.userRelaySets.keys
          .contains(selectedArticlesSource.key);
      return exist ? selectedArticlesSource : const MapEntry('top', 'top');
    }
  }

  MapEntry<String, dynamic> getLeadingSource() {
    if (selectedLeadingSourceType == AppContentSource.community) {
      return selectedLeadingSource;
    } else if (selectedLeadingSourceType == AppContentSource.relay) {
      final exist = relayInfoCubit.state.relayFeeds.favoriteRelays
          .contains(selectedLeadingSource.key);
      return exist ? selectedLeadingSource : const MapEntry('recent', 'recent');
    } else {
      final exist = relayInfoCubit.state.userRelaySets.keys
          .contains(selectedLeadingSource.key);
      return exist ? selectedLeadingSource : const MapEntry('recent', 'recent');
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> processSelectedSource(
        MapEntry<String, dynamic> source) {
      if (source.value is UserRelaySet) {
        return {source.key: (source.value as UserRelaySet).toMap()};
      }
      return {source.key: source.value};
    }

    return {
      'selectedLeadingSourceType': selectedLeadingSourceType.name,
      'selectedLeadingSource': processSelectedSource(selectedLeadingSource),
      'selectedMediaSourceType': selectedMediaSourceType.name,
      'selectedMediaSource': processSelectedSource(selectedMediaSource),
      'selectedArticlesSourceType': selectedArticlesSourceType.name,
      'selectedArticlesSource': processSelectedSource(selectedArticlesSource),
    };
  }

  String toJson() => jsonEncode(toMap());

  static AppViewConfig fromJson(String json) =>
      AppViewConfig.fromMap(jsonDecode(json));

  AppViewConfig copyWith({
    AppContentSource? selectedLeadingSourceType,
    MapEntry<String, dynamic>? selectedLeadingSource,
    AppContentSource? selectedMediaSourceType,
    MapEntry<String, dynamic>? selectedMediaSource,
    AppContentSource? selectedArticlesSourceType,
    MapEntry<String, dynamic>? selectedArticlesSource,
  }) {
    return AppViewConfig(
      selectedLeadingSourceType:
          selectedLeadingSourceType ?? this.selectedLeadingSourceType,
      selectedLeadingSource:
          selectedLeadingSource ?? this.selectedLeadingSource,
      selectedMediaSourceType:
          selectedMediaSourceType ?? this.selectedMediaSourceType,
      selectedMediaSource: selectedMediaSource ?? this.selectedMediaSource,
      selectedArticlesSourceType:
          selectedArticlesSourceType ?? this.selectedArticlesSourceType,
      selectedArticlesSource:
          selectedArticlesSource ?? this.selectedArticlesSource,
    );
  }
}
