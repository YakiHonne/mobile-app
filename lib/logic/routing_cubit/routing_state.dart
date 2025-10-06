// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'routing_cubit.dart';

class RoutingState extends Equatable {
  final CurrentRoute currentRoute;
  final UpdatingState updatingState;

  const RoutingState({
    required this.currentRoute,
    required this.updatingState,
  });

  @override
  List<Object> get props => [currentRoute, updatingState];

  RoutingState copyWith({
    CurrentRoute? currentRoute,
    UpdatingState? updatingState,
  }) {
    return RoutingState(
      currentRoute: currentRoute ?? this.currentRoute,
      updatingState: updatingState ?? this.updatingState,
    );
  }
}
