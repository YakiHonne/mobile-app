part of 'add_media_cubit.dart';

class AddMediaState extends Equatable {
  const AddMediaState({
    this.status = PublishMediaStatus.idle,
    this.progress = 0,
  });

  final PublishMediaStatus status;
  final double progress;

  @override
  List<Object> get props => [status, progress];

  AddMediaState copyWith({
    PublishMediaStatus? status,
    double? progress,
  }) {
    return AddMediaState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
    );
  }
}
