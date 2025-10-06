// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'dvm_metadata_cubit.dart';

class DvmMetadataState extends Equatable {
  final Map<String, DvmMetadata> dvmsMetadata;
  final bool refresh;

  const DvmMetadataState({
    required this.dvmsMetadata,
    required this.refresh,
  });

  @override
  List<Object> get props => [dvmsMetadata, refresh];

  DvmMetadataState copyWith({
    Map<String, DvmMetadata>? dvmsMetadata,
    bool? refresh,
  }) {
    return DvmMetadataState(
      dvmsMetadata: dvmsMetadata ?? this.dvmsMetadata,
      refresh: refresh ?? this.refresh,
    );
  }
}
