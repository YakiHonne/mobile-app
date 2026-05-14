// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'video_controller_manager_cubit.dart';

// State carries nothing — the registry lives as plain fields on the cubit.
// Widgets subscribe to per-URL streams instead of reacting to state changes.
class VideoControllerManagerState extends Equatable {
  const VideoControllerManagerState();

  @override
  List<Object> get props => const [];
}
