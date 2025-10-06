// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'update_relays_cubit.dart';

class UpdateRelaysState extends Equatable {
  final Map<String, ReadWriteMarker> relays;
  final List<String> dmRelays;
  final List<String> activeRelays;
  final Set<String> toBeDeleted;
  final Map<String, ReadWriteMarker> pendingRelays;
  final List<String> onlineRelays;
  final bool isSameRelays;

  const UpdateRelaysState({
    required this.relays,
    required this.activeRelays,
    required this.toBeDeleted,
    required this.pendingRelays,
    required this.onlineRelays,
    required this.isSameRelays,
    required this.dmRelays,
  });

  @override
  List<Object> get props => [
        activeRelays,
        relays,
        isSameRelays,
        onlineRelays,
        activeRelays,
        pendingRelays,
        toBeDeleted,
        dmRelays,
      ];

  UpdateRelaysState copyWith({
    Map<String, ReadWriteMarker>? relays,
    List<String>? dmRelays,
    List<String>? activeRelays,
    Set<String>? toBeDeleted,
    Map<String, ReadWriteMarker>? pendingRelays,
    List<String>? onlineRelays,
    bool? isSameRelays,
  }) {
    return UpdateRelaysState(
      relays: relays ?? this.relays,
      dmRelays: dmRelays ?? this.dmRelays,
      activeRelays: activeRelays ?? this.activeRelays,
      toBeDeleted: toBeDeleted ?? this.toBeDeleted,
      pendingRelays: pendingRelays ?? this.pendingRelays,
      onlineRelays: onlineRelays ?? this.onlineRelays,
      isSameRelays: isSameRelays ?? this.isSameRelays,
    );
  }
}
