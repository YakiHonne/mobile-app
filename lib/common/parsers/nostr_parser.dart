// import 'package:nostr_core_enhanced/nostr/nostr.dart';
// import 'package:nostr_core_enhanced/utils/utils.dart'; // For Nip19

// /// Block types
// abstract class Block {}

// class TextBlock extends Block {
//   final String text;
//   TextBlock(this.text);
//   @override
//   String toString() => 'TextBlock: $text';

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//       other is TextBlock &&
//           runtimeType == other.runtimeType &&
//           text == other.text;

//   @override
//   int get hashCode => text.hashCode;
// }

// class HashtagBlock extends Block {
//   final String value;
//   HashtagBlock(this.value);
//   @override
//   String toString() => 'HashtagBlock: $value';
// }

// class ReferenceBlock extends Block {
//   final dynamic pointer; // ProfilePointer | AddressPointer | EventPointer
//   ReferenceBlock(this.pointer);
//   @override
//   String toString() => 'ReferenceBlock: $pointer';
// }

// class ImageBlock extends Block {
//   final String url;
//   ImageBlock(this.url);
//   @override
//   String toString() => 'ImageBlock: $url';
// }

// class VideoBlock extends Block {
//   final String url;
//   VideoBlock(this.url);
//   @override
//   String toString() => 'VideoBlock: $url';
// }

// class AudioBlock extends Block {
//   final String url;
//   AudioBlock(this.url);
//   @override
//   String toString() => 'AudioBlock: $url';
// }

// class UrlBlock extends Block {
//   final String url;
//   UrlBlock(this.url);
//   @override
//   String toString() => 'UrlBlock: $url';
// }

// class RelayBlock extends Block {
//   final String url;
//   RelayBlock(this.url);
//   @override
//   String toString() => 'RelayBlock: $url';
// }

// class EmojiBlock extends Block {
//   final String type = 'emoji';
//   final String shortcode;
//   final String url;
//   EmojiBlock({required this.shortcode, required this.url});
//   @override
//   String toString() => 'EmojiBlock: :$shortcode:';
// }

// // Pointers
// class ProfilePointer {
//   final String pubkey;
//   final List<String>? relays;
//   ProfilePointer({required this.pubkey, this.relays});
//   @override
//   String toString() => 'ProfilePointer: $pubkey';
// }

// class EventPointer {
//   final String id;
//   final List<String>? relays;
//   final String? pubkey;
//   final int? kind;
//   EventPointer({required this.id, this.relays, this.pubkey, this.kind});
//   @override
//   String toString() => 'EventPointer: $id';
// }

// class AddressPointer {
//   final String identifier;
//   final String pubkey;
//   final int kind;
//   final List<String>? relays;
//   AddressPointer(
//       {required this.identifier,
//       required this.pubkey,
//       required this.kind,
//       this.relays});
//   @override
//   String toString() => 'AddressPointer: $identifier';
// }

// const int MAX_HASHTAG_LENGTH = 42;

// // Regular Expressions matching the TypeScript definitions
// final RegExp noCharacter = RegExp(r'\W', multiLine: true);
// final RegExp noURLCharacter =
//     RegExp(r'[^\w\/] |[^\w\/]$|$|,| ', multiLine: true);

// // Helper to simulate 'decode' behavior wrapper around Nip19
// ({String type, dynamic data}) decode(String text) {
//   if (text.startsWith('npub1')) {
//     return (type: 'npub', data: Nip19.decodePubkey(text));
//   } else if (text.startsWith('note1')) {
//     return (type: 'note', data: Nip19.decodeNote(text));
//   } else if (text.startsWith('nsec1')) {
//     return (type: 'nsec', data: null);
//   } else if (text.startsWith('nevent1')) {
//     final map = Nip19.decodeShareableEntity(text);
//     return (
//       type: 'nevent',
//       data: EventPointer(
//         id: map['special'] ?? '',
//         relays: (map['relays'] as List?)?.cast<String>(),
//         pubkey: map['author'],
//         kind: map['kind'],
//       )
//     );
//   } else if (text.startsWith('nprofile1')) {
//     final map = Nip19.decodeShareableEntity(text);
//     return (
//       type: 'nprofile',
//       data: ProfilePointer(
//         pubkey: map['special'] ?? '',
//         relays: (map['relays'] as List?)?.cast<String>(),
//       )
//     );
//   } else if (text.startsWith('naddr1')) {
//     final map = Nip19.decodeShareableEntity(text);
//     return (
//       type: 'naddr',
//       data: AddressPointer(
//         identifier: map['special'] ?? '', // Assuming identifier is in 'special'
//         pubkey: map['author'] ?? '',
//         kind: map['kind'] ?? 0,
//         relays: (map['relays'] as List?)?.cast<String>(),
//       )
//     );
//   }
//   throw Exception('Unknown nip19 type');
// }

// Iterable<Block> parse(dynamic content) sync* {
//   String textContent = '';
//   List<EmojiBlock> emojis = [];

//   if (content is String) {
//     textContent = content;
//   } else if (content is Event) {
//     textContent = content.content;
//     if (content.tags.isNotEmpty) {
//       for (final tag in content.tags) {
//         if (tag is List && tag.length >= 3 && tag[0] == 'emoji') {
//           emojis.add(EmojiBlock(shortcode: tag[1], url: tag[2]));
//         }
//       }
//     }
//   } else {
//     textContent = content.toString();
//   }

//   final int max = textContent.length;
//   int prevIndex = 0;
//   int index = 0;

//   mainLoop:
//   while (index < max) {
//     final int u = textContent.indexOf(':', index);
//     final int h = textContent.indexOf('#', index);

//     if (u == -1 && h == -1) {
//       break;
//     }

//     if (u == -1 || (h >= 0 && h < u)) {
//       // parse hashtag
//       if (h == 0 || textContent[h - 1] == ' ') {
//         int sliceStart = h + 1;
//         int sliceEnd =
//             (h + MAX_HASHTAG_LENGTH < max) ? h + MAX_HASHTAG_LENGTH : max;

//         if (sliceStart >= max) {
//           // Nothing after hash
//           index = h + 1;
//           continue mainLoop;
//         }

//         String slice = textContent.substring(sliceStart, sliceEnd);
//         final match = noCharacter.firstMatch(slice);

//         int end;
//         if (match != null) {
//           end = h + 1 + match.start;
//         } else {
//           // If no terminator found, user logic implies it goes to 'max' (end of file)
//           // or end of regex search.
//           // TS: `const end = m ? h + 1 + m.index! : max` (where max is content.length)
//           // This implies if a hashtag is longer than MAX_HASHTAG_LENGTH, it just takes standard max?
//           // Wait. `content.slice(h+1, h+MAX)`
//           // If `match` fails (returns null), then `end` becomes `max`.
//           // This means if I have `#verylonghashtag` > 42 chars, `match` against `noCharacter` will likely find nothing if it's all valid chars.
//           // Then `end` becomes `max`.
//           // So it consumes the REST OF THE FILE as the hashtag?
//           // That seems to be the literal translation of the user code provided.
//           end = max;
//         }

//         if (prevIndex != h) {
//           yield TextBlock(textContent.substring(prevIndex, h));
//         }

//         yield HashtagBlock(textContent.substring(h + 1, end));
//         index = end;
//         prevIndex = index;
//         continue mainLoop;
//       }

//       index = h + 1;
//       continue mainLoop;
//     }

//     // otherwise parse things that have an ":"
//     if (u >= 5 && textContent.substring(u - 5, u) == 'nostr') {
//       int checkStart = u + 60; // Skip assumed prefix length
//       // User code matches against `content.slice(u+60)`

//       if (checkStart <= max) {
//         String checkSlice = textContent.substring(checkStart);
//         final match = noCharacter.firstMatch(checkSlice);
//         int end = match != null ? checkStart + match.start : max;

//         try {
//           final encoded = textContent.substring(u + 1, end);
//           final result = decode(encoded);

//           dynamic pointer;
//           String type = result.type;
//           dynamic data = result.data;

//           if (type == 'npub') {
//             pointer = ProfilePointer(pubkey: data);
//           } else if (type == 'note') {
//             pointer = EventPointer(id: data);
//           } else if (type == 'nsec') {
//             // ignore this, treat it as not a valid uri
//             index = end + 1;
//             continue mainLoop;
//           } else {
//             // nprofile, nevent, naddr, etc.
//             pointer = data;
//           }

//           if (prevIndex != u - 5) {
//             yield TextBlock(textContent.substring(prevIndex, u - 5));
//           }
//           yield ReferenceBlock(pointer);
//           index = end;
//           prevIndex = index;
//           continue mainLoop;
//         } catch (e) {
//           index = u + 1;
//           continue mainLoop;
//         }
//       } else {
//         index = u + 1;
//         continue mainLoop;
//       }
//     } else if ((u >= 5 && textContent.substring(u - 5, u) == 'https') ||
//         (u >= 4 && textContent.substring(u - 4, u) == 'http')) {
//       int offset = textContent.substring(u - 1, u) == 's' ? 5 : 4;
//       int start = u - offset;

//       int checkStart = u + 4;

//       if (checkStart < max) {
//         String checkSlice = textContent.substring(checkStart);
//         final match = noURLCharacter.firstMatch(checkSlice);
//         int end = match != null ? checkStart + match.start : max;

//         try {
//           String urlString = textContent.substring(start, end);
//           Uri url = Uri.parse(urlString);
//           if (!url.host.contains('.')) {
//             throw Exception('invalid url');
//           }

//           if (prevIndex != start) {
//             yield TextBlock(textContent.substring(prevIndex, start));
//           }

//           String path = url.path.toLowerCase();
//           final imageRegex = RegExp(r'\.(png|jpe?g|gif|webp|heic|svg)$');
//           final videoRegex = RegExp(r'\.(mp4|avi|webm|mkv|mov)$');
//           final audioRegex = RegExp(r'\.(mp3|aac|ogg|opus|wav|flac)$');

//           if (imageRegex.hasMatch(path)) {
//             yield ImageBlock(urlString);
//           } else if (videoRegex.hasMatch(path)) {
//             yield VideoBlock(urlString);
//           } else if (audioRegex.hasMatch(path)) {
//             yield AudioBlock(urlString);
//           } else {
//             yield UrlBlock(urlString);
//           }

//           index = end;
//           prevIndex = index;
//           continue mainLoop;
//         } catch (e) {
//           index = end + 1;
//           continue mainLoop;
//         }
//       } else {
//         // Too short
//         index = end + 1;
//         continue mainLoop;
//       }
//     } else if ((u >= 3 && textContent.substring(u - 3, u) == 'wss') ||
//         (u >= 2 && textContent.substring(u - 2, u) == 'ws')) {
//       int offset = textContent.substring(u - 1, u) == 's' ? 3 : 2;
//       int start = u - offset;
//       int checkStart = u + 4;

//       if (checkStart < max) {
//         String checkSlice = textContent.substring(checkStart);
//         final match = noURLCharacter.firstMatch(checkSlice);
//         int end = match != null ? checkStart + match.start : max;

//         try {
//           String urlString = textContent.substring(start, end);
//           Uri url = Uri.parse(urlString);
//           if (!url.host.contains('.')) {
//             throw Exception('invalid ws url');
//           }

//           if (prevIndex != start) {
//             yield TextBlock(textContent.substring(prevIndex, start));
//           }
//           yield RelayBlock(urlString);

//           index = end;
//           prevIndex = index;
//           continue mainLoop;
//         } catch (e) {
//           index = end + 1;
//           continue mainLoop;
//         }
//       } else {
//         index = max; // or end?
//         index = u + 1; // safer fallback
//         continue mainLoop;
//       }
//     } else {
//       // try to parse an emoji shortcode
//       bool foundEmoji = false;
//       for (final emoji in emojis) {
//         String shortcodeWithColons = ':${emoji.shortcode}:';
//         int len = shortcodeWithColons.length;

//         if (u + len <= max) {
//           String potential = textContent.substring(u, u + len); // u matches ':'
//           if (potential == shortcodeWithColons) {
//             if (prevIndex != u) {
//               yield TextBlock(textContent.substring(prevIndex, u));
//             }
//             yield emoji;
//             index = u + len; // u + shortcode + 1 + 1 (2 colons)
//             prevIndex = index;
//             foundEmoji = true;
//             break;
//           }
//         }
//       }

//       if (foundEmoji) {
//         continue mainLoop;
//       }

//       index = u + 1;
//       continue mainLoop;
//     }
//   }

//   if (prevIndex < max) {
//     yield TextBlock(textContent.substring(prevIndex));
//   }
// }
