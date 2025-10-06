// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'wot_configuration_cubit.dart';

class WotConfigurationState extends Equatable {
  final double threshold;
  final bool notifications;
  final bool privateMessages;
  final bool postActions;

  const WotConfigurationState({
    required this.threshold,
    required this.notifications,
    required this.privateMessages,
    required this.postActions,
  });

  @override
  List<Object> get props => [
        threshold,
        notifications,
        privateMessages,
        postActions,
      ];

  WotConfigurationState copyWith({
    double? threshold,
    bool? notifications,
    bool? privateMessages,
    bool? postActions,
  }) {
    return WotConfigurationState(
      threshold: threshold ?? this.threshold,
      notifications: notifications ?? this.notifications,
      privateMessages: privateMessages ?? this.privateMessages,
      postActions: postActions ?? this.postActions,
    );
  }
}
