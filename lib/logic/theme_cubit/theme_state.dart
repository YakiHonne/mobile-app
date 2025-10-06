// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final double textScaleFactor;
  final AppThemeMode mode;
  final ThemeData theme;

  const ThemeState({
    required this.textScaleFactor,
    required this.mode,
    required this.theme,
  });

  @override
  List<Object> get props => [
        textScaleFactor,
        mode,
        theme,
      ];

  ThemeState copyWith({
    double? textScaleFactor,
    AppThemeMode? mode,
    ThemeData? theme,
  }) {
    return ThemeState(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
    );
  }
}
