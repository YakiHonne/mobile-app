// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_video_cubit.dart';

class WriteVideoState extends Equatable {
  final List<String> tags;
  final List<String> suggestions;
  final VideoPublishSteps videoPublishSteps;
  final String videoUrl;
  final String title;
  final String summary;
  final bool contentWarning;
  final String mimeType;
  final bool isUpdating;
  final bool isZapSplitEnabled;
  final List<ZapSplit> zapsSplits;
  final String imageLink;
  final bool isHorizontal;

  const WriteVideoState({
    required this.tags,
    required this.suggestions,
    required this.videoPublishSteps,
    required this.videoUrl,
    required this.title,
    required this.summary,
    required this.contentWarning,
    required this.mimeType,
    required this.isUpdating,
    required this.isZapSplitEnabled,
    required this.zapsSplits,
    required this.imageLink,
    required this.isHorizontal,
  });

  @override
  List<Object> get props => [
        tags,
        suggestions,
        videoPublishSteps,
        videoUrl,
        title,
        summary,
        imageLink,
        contentWarning,
        mimeType,
        isUpdating,
        isZapSplitEnabled,
        zapsSplits,
        isHorizontal,
      ];

  WriteVideoState copyWith({
    List<String>? tags,
    List<String>? suggestions,
    VideoPublishSteps? videoPublishSteps,
    String? videoUrl,
    String? title,
    String? summary,
    bool? contentWarning,
    String? mimeType,
    bool? isUpdating,
    bool? isZapSplitEnabled,
    List<ZapSplit>? zapsSplits,
    String? imageLink,
    bool? isHorizontal,
  }) {
    return WriteVideoState(
      tags: tags ?? this.tags,
      suggestions: suggestions ?? this.suggestions,
      videoPublishSteps: videoPublishSteps ?? this.videoPublishSteps,
      videoUrl: videoUrl ?? this.videoUrl,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contentWarning: contentWarning ?? this.contentWarning,
      mimeType: mimeType ?? this.mimeType,
      isUpdating: isUpdating ?? this.isUpdating,
      isZapSplitEnabled: isZapSplitEnabled ?? this.isZapSplitEnabled,
      zapsSplits: zapsSplits ?? this.zapsSplits,
      imageLink: imageLink ?? this.imageLink,
      isHorizontal: isHorizontal ?? this.isHorizontal,
    );
  }
}
