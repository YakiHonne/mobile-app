// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'crashlytics_cubit.dart';

class CrashlyticsState extends Equatable {
  final bool isCrashlyticsEnabled;
  final bool automaticCachePurge;
  final double dataCacheSize;
  final double mediaCacheSize;
  final bool isDataCacheToggled;
  final bool isMediaCacheToggled;

  const CrashlyticsState({
    required this.isCrashlyticsEnabled,
    required this.automaticCachePurge,
    required this.dataCacheSize,
    required this.mediaCacheSize,
    required this.isDataCacheToggled,
    required this.isMediaCacheToggled,
  });

  @override
  List<Object> get props => [
        isCrashlyticsEnabled,
        automaticCachePurge,
        dataCacheSize,
        mediaCacheSize,
        isDataCacheToggled,
        isMediaCacheToggled,
      ];

  CrashlyticsState copyWith({
    bool? isCrashlyticsEnabled,
    bool? automaticCachePurge,
    double? dataCacheSize,
    double? mediaCacheSize,
    bool? isDataCacheToggled,
    bool? isMediaCacheToggled,
  }) {
    return CrashlyticsState(
      isCrashlyticsEnabled: isCrashlyticsEnabled ?? this.isCrashlyticsEnabled,
      automaticCachePurge: automaticCachePurge ?? this.automaticCachePurge,
      dataCacheSize: dataCacheSize ?? this.dataCacheSize,
      mediaCacheSize: mediaCacheSize ?? this.mediaCacheSize,
      isDataCacheToggled: isDataCacheToggled ?? this.isDataCacheToggled,
      isMediaCacheToggled: isMediaCacheToggled ?? this.isMediaCacheToggled,
    );
  }
}
