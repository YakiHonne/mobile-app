// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'write_smart_widget_cubit.dart';

class WriteSmartWidgetState extends Equatable {
  final SmartWidgetPublishSteps smartWidgetPublishSteps;
  final String title;
  final List<String> keywords;
  final String icon;
  final SmartWidgetBox smartWidgetBox;
  final bool smartWidgetUpdate;
  final bool toggleDisplay;
  final bool isOnboarding;
  final SWType swType;
  final AppSmartWidget appSmartWidget;

  const WriteSmartWidgetState({
    required this.smartWidgetPublishSteps,
    required this.title,
    required this.keywords,
    required this.icon,
    required this.smartWidgetBox,
    required this.smartWidgetUpdate,
    required this.toggleDisplay,
    required this.isOnboarding,
    required this.swType,
    required this.appSmartWidget,
  });

  @override
  List<Object> get props => [
        smartWidgetPublishSteps,
        title,
        smartWidgetBox,
        smartWidgetUpdate,
        toggleDisplay,
        isOnboarding,
        keywords,
        icon,
        swType,
        appSmartWidget,
      ];

  WriteSmartWidgetState copyWith({
    SmartWidgetPublishSteps? smartWidgetPublishSteps,
    String? title,
    List<String>? keywords,
    String? icon,
    SmartWidgetBox? smartWidgetBox,
    bool? smartWidgetUpdate,
    bool? toggleDisplay,
    bool? isOnboarding,
    SWType? swType,
    AppSmartWidget? appSmartWidget,
  }) {
    return WriteSmartWidgetState(
      smartWidgetPublishSteps:
          smartWidgetPublishSteps ?? this.smartWidgetPublishSteps,
      title: title ?? this.title,
      keywords: keywords ?? this.keywords,
      icon: icon ?? this.icon,
      smartWidgetBox: smartWidgetBox ?? this.smartWidgetBox,
      smartWidgetUpdate: smartWidgetUpdate ?? this.smartWidgetUpdate,
      toggleDisplay: toggleDisplay ?? this.toggleDisplay,
      isOnboarding: isOnboarding ?? this.isOnboarding,
      swType: swType ?? this.swType,
      appSmartWidget: appSmartWidget ?? this.appSmartWidget,
    );
  }
}
