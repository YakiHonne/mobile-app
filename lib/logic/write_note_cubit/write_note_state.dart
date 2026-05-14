// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_note_cubit.dart';

class WriteNoteState extends Equatable {
  final List<String> medias;
  final List<Map<String, String>> imetas;
  final BaseEventModel? quotedContent;
  final bool isQuotedContentAvailable;
  final bool isMention;
  final bool isQuote;

  const WriteNoteState({
    required this.medias,
    required this.imetas,
    this.quotedContent,
    required this.isQuotedContentAvailable,
    required this.isMention,
    required this.isQuote,
  });

  @override
  List<Object> get props => [
        medias,
        imetas,
        isQuotedContentAvailable,
        isMention,
        isQuote,
      ];

  WriteNoteState copyWith({
    List<String>? medias,
    List<Map<String, String>>? imetas,
    BaseEventModel? quotedContent,
    bool? isQuotedContentAvailable,
    bool? isMention,
    bool? isQuote,
  }) {
    return WriteNoteState(
      medias: medias ?? this.medias,
      imetas: imetas ?? this.imetas,
      quotedContent: quotedContent ?? this.quotedContent,
      isQuotedContentAvailable:
          isQuotedContentAvailable ?? this.isQuotedContentAvailable,
      isMention: isMention ?? this.isMention,
      isQuote: isQuote ?? this.isQuote,
    );
  }
}
