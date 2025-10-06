// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'un_flash_news_details_cubit.dart';

class UnFlashNewsDetailsState extends Equatable {
  final bool isBookmarked;
  final List<UncensoredNote> uncensoredNotes;
  final bool loading;
  final WritingNoteStatus writingNoteStatus;
  final bool isSealed;
  final List<SealedNote> notHelpFulNotes;
  final bool refresh;

  const UnFlashNewsDetailsState({
    required this.isBookmarked,
    required this.uncensoredNotes,
    required this.loading,
    required this.writingNoteStatus,
    required this.isSealed,
    required this.notHelpFulNotes,
    required this.refresh,
  });

  @override
  List<Object> get props => [
        isBookmarked,
        uncensoredNotes,
        loading,
        writingNoteStatus,
        isSealed,
        notHelpFulNotes,
        refresh,
      ];

  UnFlashNewsDetailsState copyWith({
    bool? isBookmarked,
    List<UncensoredNote>? uncensoredNotes,
    bool? loading,
    WritingNoteStatus? writingNoteStatus,
    bool? isSealed,
    List<SealedNote>? notHelpFulNotes,
    bool? refresh,
  }) {
    return UnFlashNewsDetailsState(
      isBookmarked: isBookmarked ?? this.isBookmarked,
      uncensoredNotes: uncensoredNotes ?? this.uncensoredNotes,
      loading: loading ?? this.loading,
      writingNoteStatus: writingNoteStatus ?? this.writingNoteStatus,
      isSealed: isSealed ?? this.isSealed,
      notHelpFulNotes: notHelpFulNotes ?? this.notHelpFulNotes,
      refresh: refresh ?? this.refresh,
    );
  }
}
