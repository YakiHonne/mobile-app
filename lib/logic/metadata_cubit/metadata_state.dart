// // ignore_for_file: public_member_api_docs, sort_constructors_first
// part of 'metadata_cubit.dart';

// class MetadataState extends Equatable {
//   final bool isLoading;
//   final Map<String, MapEntry<Metadata, int>> metadatas;
//   final Map<String, MapEntry<Nip05, int>> nip05;
//   final Set<String> loadingPubkeys;
//   final int lastUpdated;

//   const MetadataState({
//     required this.isLoading,
//     required this.metadatas,
//     required this.nip05,
//     required this.loadingPubkeys,
//     required this.lastUpdated,
//   });

//   /// Get metadata without side effects - timestamp is NOT updated
//   /// Use this for BlocSelector to avoid unnecessary rebuilds
//   Metadata? getMetadata(String pubkey) {
//     return metadatas[pubkey]?.key;
//   }

//   /// Check if metadata is currently being loaded from network
//   bool isMetadataLoading(String pubkey) {
//     return loadingPubkeys.contains(pubkey);
//   }

//   /// Get NIP05 without side effects - timestamp is NOT updated
//   /// Use this for BlocSelector to avoid unnecessary rebuilds
//   Nip05? getNip05(String pubkey) {
//     return nip05[pubkey]?.key;
//   }

//   /// Check if metadata exists in cache (regardless of age)
//   bool hasMetadata(String pubkey) {
//     return metadatas.containsKey(pubkey);
//   }

//   /// Check if NIP05 exists in cache (regardless of age)
//   bool hasNip05(String pubkey) {
//     return nip05.containsKey(pubkey);
//   }

//   /// Get metadata age in seconds (how long since last accessed)
//   int? getMetadataAge(String pubkey) {
//     final entry = metadatas[pubkey];
//     if (entry == null) {
//       return null;
//     }
//     return Helpers.now - entry.value;
//   }

//   /// Get NIP05 age in seconds (how long since last accessed)
//   int? getNip05Age(String pubkey) {
//     final entry = nip05[pubkey];
//     if (entry == null) {
//       return null;
//     }
//     return Helpers.now - entry.value;
//   }

//   /// Get cache statistics (useful for debugging)
//   Map<String, dynamic> getCacheStats() {
//     final now = Helpers.now;
//     final metadataAges = metadatas.values.map((e) => now - e.value).toList();
//     final nip05Ages = nip05.values.map((e) => now - e.value).toList();

//     return {
//       'metadataCount': metadatas.length,
//       'nip05Count': nip05.length,
//       'loadingCount': loadingPubkeys.length,
//       'avgMetadataAge': metadataAges.isNotEmpty
//           ? metadataAges.reduce((a, b) => a + b) / metadataAges.length
//           : 0,
//       'avgNip05Age': nip05Ages.isNotEmpty
//           ? nip05Ages.reduce((a, b) => a + b) / nip05Ages.length
//           : 0,
//       'oldestMetadata': metadataAges.isNotEmpty
//           ? metadataAges.reduce((a, b) => a > b ? a : b)
//           : 0,
//       'oldestNip05':
//           nip05Ages.isNotEmpty ? nip05Ages.reduce((a, b) => a > b ? a : b) : 0,
//     };
//   }

//   @override
//   List<Object> get props => [
//         isLoading,
//         metadatas,
//         nip05,
//         loadingPubkeys,
//         lastUpdated,
//       ];

//   MetadataState copyWith({
//     bool? isLoading,
//     Map<String, MapEntry<Metadata, int>>? metadatas,
//     Map<String, MapEntry<Nip05, int>>? nip05,
//     Set<String>? loadingPubkeys,
//     int? lastUpdated,
//   }) {
//     return MetadataState(
//       isLoading: isLoading ?? this.isLoading,
//       metadatas: metadatas ?? this.metadatas,
//       nip05: nip05 ?? this.nip05,
//       loadingPubkeys: loadingPubkeys ?? this.loadingPubkeys,
//       lastUpdated: lastUpdated ?? this.lastUpdated,
//     );
//   }
// }

// ignore_for_file: public_member_api_docs, sort_constructors_first

part of 'metadata_cubit.dart';

class MetadataState extends Equatable {
  final Set<String> metadataPubkeys;
  final Set<String> nip05Pubkeys;
  final Map<String, bool> nip05Status;
  final Map<String, Metadata> metadataCache; // In-memory cache

  const MetadataState({
    this.metadataPubkeys = const {},
    this.nip05Status = const {},
    this.metadataCache = const {},
    this.nip05Pubkeys = const {},
  });

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

// class MetadataState extends Equatable {
//   final Set<String> metadataPubkeys;
//   final Set<String> nip05Pubkeys;

//   const MetadataState({
//     this.metadataPubkeys = const {},
//     this.nip05Pubkeys = const {},
//   });

//   // Convenience methods
//   bool hasMetadata(String pubkey) => metadataPubkeys.contains(pubkey);
//   bool hasNip05(String pubkey) => nip05Pubkeys.contains(pubkey);

//   @override
//   List<Object> get props => [metadataPubkeys, nip05Pubkeys];

//   MetadataState copyWith({
//     Set<String>? metadataPubkeys,
//     Set<String>? nip05Pubkeys,
//   }) {
//     return MetadataState(
//       metadataPubkeys: metadataPubkeys ?? this.metadataPubkeys,
//       nip05Pubkeys: nip05Pubkeys ?? this.nip05Pubkeys,
//     );
//   }
// }
