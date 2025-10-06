// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'smart_widget_app_cubit.dart';

class SmartWidgetAppState extends Equatable {
  final bool isReady;

  const SmartWidgetAppState({
    required this.isReady,
  });

  @override
  List<Object> get props => [isReady];

  SmartWidgetAppState copyWith({
    bool? isReady,
  }) {
    return SmartWidgetAppState(
      isReady: isReady ?? this.isReady,
    );
  }
}
