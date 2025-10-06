// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'media_servers_cubit.dart';

class MediaServersState extends Equatable {
  final bool isBlossomActive;
  final List<String> blossomServers;
  final List<String> regularServers;
  final String activeRegularServer;
  final String activeBlossomServer;
  final bool enableMirroring;

  const MediaServersState({
    required this.isBlossomActive,
    required this.blossomServers,
    required this.regularServers,
    required this.activeRegularServer,
    required this.activeBlossomServer,
    required this.enableMirroring,
  });

  @override
  List<Object> get props => [
        isBlossomActive,
        blossomServers,
        regularServers,
        activeRegularServer,
        activeBlossomServer,
        enableMirroring,
      ];

  MediaServersState copyWith({
    bool? isBlossomActive,
    List<String>? blossomServers,
    List<String>? regularServers,
    String? activeRegularServer,
    String? activeBlossomServer,
    bool? enableMirroring,
  }) {
    return MediaServersState(
      isBlossomActive: isBlossomActive ?? this.isBlossomActive,
      blossomServers: blossomServers ?? this.blossomServers,
      regularServers: regularServers ?? this.regularServers,
      activeRegularServer: activeRegularServer ?? this.activeRegularServer,
      activeBlossomServer: activeBlossomServer ?? this.activeBlossomServer,
      enableMirroring: enableMirroring ?? this.enableMirroring,
    );
  }
}
