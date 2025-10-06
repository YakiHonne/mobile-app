// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'smart_widgets_cubit.dart';

class SmartWidgetsState extends Equatable {
  final List<SmartWidget> widgets;
  final bool isLoading;
  final UpdatingState loadingState;
  final List<String> mutes;

  const SmartWidgetsState({
    required this.widgets,
    required this.isLoading,
    required this.loadingState,
    required this.mutes,
  });

  @override
  List<Object> get props => [
        widgets,
        isLoading,
        loadingState,
        mutes,
      ];

  SmartWidgetsState copyWith({
    List<SmartWidget>? widgets,
    bool? isLoading,
    UpdatingState? loadingState,
    List<String>? mutes,
  }) {
    return SmartWidgetsState(
      widgets: widgets ?? this.widgets,
      isLoading: isLoading ?? this.isLoading,
      loadingState: loadingState ?? this.loadingState,
      mutes: mutes ?? this.mutes,
    );
  }
}
