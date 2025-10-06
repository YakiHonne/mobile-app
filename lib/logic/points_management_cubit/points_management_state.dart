// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'points_management_cubit.dart';

class PointsManagementState extends Equatable {
  final UserGlobalStats? userGlobalStats;
  final bool isUpdated;
  final bool isNew;
  final List<String> standards;
  final int currentXp;
  final int currentLevel;
  final int nextLevelXp;
  final int additionalXp;
  final int currentLevelXp;
  final int consumablePoints;
  final double percentage;

  const PointsManagementState({
    this.userGlobalStats,
    required this.isUpdated,
    required this.isNew,
    required this.standards,
    required this.currentXp,
    required this.currentLevel,
    required this.nextLevelXp,
    required this.additionalXp,
    required this.currentLevelXp,
    required this.consumablePoints,
    required this.percentage,
  });

  @override
  List<Object> get props => [
        isUpdated,
        isNew,
        standards,
        currentXp,
        currentLevel,
        nextLevelXp,
        additionalXp,
        currentLevelXp,
        consumablePoints,
        percentage,
      ];

  PointsManagementState copyWith({
    UserGlobalStats? userGlobalStats,
    bool? isUpdated,
    bool? isNew,
    List<String>? standards,
    int? currentXp,
    int? currentLevel,
    int? nextLevelXp,
    int? additionalXp,
    int? currentLevelXp,
    int? consumablePoints,
    double? percentage,
  }) {
    return PointsManagementState(
      userGlobalStats: userGlobalStats,
      isUpdated: isUpdated ?? this.isUpdated,
      isNew: isNew ?? this.isNew,
      standards: standards ?? this.standards,
      currentXp: currentXp ?? this.currentXp,
      currentLevel: currentLevel ?? this.currentLevel,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      additionalXp: additionalXp ?? this.additionalXp,
      currentLevelXp: currentLevelXp ?? this.currentLevelXp,
      consumablePoints: consumablePoints ?? this.consumablePoints,
      percentage: percentage ?? this.percentage,
    );
  }
}
