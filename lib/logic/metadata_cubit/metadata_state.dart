part of 'metadata_cubit.dart';

class MetadataState extends Equatable {
  // In-memory cache

  const MetadataState({
    this.metadataPubkeys = const {},
    this.nip05Status = const {},
    this.metadataCache = const {},
    this.nip05Pubkeys = const {},
  });

  final Set<String> metadataPubkeys;
  final Set<String> nip05Pubkeys;
  final Map<String, bool> nip05Status;
  final Map<String, Metadata> metadataCache;

  MetadataState copyWith({
    Set<String>? metadataPubkeys,
    Map<String, bool>? nip05Status,
    Map<String, Metadata>? metadataCache,
    Set<String>? nip05Pubkeys,
  }) {
    return MetadataState(
      metadataPubkeys: metadataPubkeys ?? this.metadataPubkeys,
      nip05Status: nip05Status ?? this.nip05Status,
      metadataCache: metadataCache ?? this.metadataCache,
      nip05Pubkeys: nip05Pubkeys ?? this.nip05Pubkeys,
    );
  }

  @override
  List<Object?> get props => [
        metadataPubkeys,
        nip05Status,
        metadataCache,
        nip05Pubkeys,
      ];
}
