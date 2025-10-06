// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_zap_poll_cubit.dart';

class WriteZapPollState extends Equatable {
  final List<String> images;
  final List<String> options;

  const WriteZapPollState({
    required this.images,
    required this.options,
  });

  @override
  List<Object> get props => [
        images,
        options,
      ];

  WriteZapPollState copyWith({
    List<String>? images,
    List<String>? options,
  }) {
    return WriteZapPollState(
      images: images ?? this.images,
      options: options ?? this.options,
    );
  }
}
