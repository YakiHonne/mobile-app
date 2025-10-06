// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'smart_widget_templates_cubit.dart';

class SmartWidgetTemplatesState extends Equatable {
  const SmartWidgetTemplatesState({
    required this.smartWidgets,
    required this.updatingState,
  });

  final List<SmartWidgetTemplate> smartWidgets;
  final UpdatingState updatingState;

  @override
  List<Object> get props => [
        smartWidgets,
        updatingState,
      ];

  SmartWidgetTemplatesState copyWith({
    List<SmartWidgetTemplate>? smartWidgets,
    UpdatingState? updatingState,
  }) {
    return SmartWidgetTemplatesState(
      smartWidgets: smartWidgets ?? this.smartWidgets,
      updatingState: updatingState ?? this.updatingState,
    );
  }
}
