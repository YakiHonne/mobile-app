// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final double textScaleFactor;
  final AppThemeMode mode;
  final bool isFluid;
  final bool fluidCards;
  final GlassQuality glassQuality;
  final ThemeData theme;
  final Color primaryColor;

  const ThemeState({
    required this.textScaleFactor,
    required this.mode,
    required this.isFluid,
    required this.fluidCards,
    required this.glassQuality,
    required this.theme,
    required this.primaryColor,
  });

  @override
  List<Object> get props => [
        textScaleFactor,
        mode,
        isFluid,
        fluidCards,
        glassQuality,
        theme,
        primaryColor,
      ];

  ThemeState copyWith({
    double? textScaleFactor,
    AppThemeMode? mode,
    bool? isFluid,
    bool? fluidCards,
    GlassQuality? glassQuality,
    ThemeData? theme,
    Color? primaryColor,
  }) {
    return ThemeState(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      mode: mode ?? this.mode,
      isFluid: isFluid ?? this.isFluid,
      fluidCards: fluidCards ?? this.fluidCards,
      glassQuality: glassQuality ?? this.glassQuality,
      theme: theme ?? this.theme,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}
