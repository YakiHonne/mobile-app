// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_note_cubit.dart';

class WriteNoteState extends Equatable {
  final List<String> medias;
  final BaseEventModel? quotedContent;
  final bool isQuotedContentAvailable;
  final bool isMention;

  const WriteNoteState({
    required this.medias,
    this.quotedContent,
    required this.isQuotedContentAvailable,
    required this.isMention,
  });

  @override
  List<Object> get props => [
        medias,
        isQuotedContentAvailable,
        isMention,
      ];

  WriteNoteState copyWith({
    List<String>? medias,
    BaseEventModel? quotedContent,
    bool? isQuotedContentAvailable,
    bool? isMention,
  }) {
    return WriteNoteState(
      medias: medias ?? this.medias,
      quotedContent: quotedContent ?? this.quotedContent,
      isQuotedContentAvailable:
          isQuotedContentAvailable ?? this.isQuotedContentAvailable,
      isMention: isMention ?? this.isMention,
    );
  }
}
