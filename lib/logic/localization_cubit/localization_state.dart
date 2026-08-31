// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'localization_cubit.dart';

class LocalizationState extends Equatable {
  final TranslationServices translationServices;

  /// Target language for content translation, '' = follow the app language.
  final String contentLanguage;

  const LocalizationState({
    required this.translationServices,
    this.contentLanguage = '',
  });

  @override
  List<Object> get props => [translationServices, contentLanguage];

  LocalizationState copyWith({
    TranslationServices? translationServices,
    String? contentLanguage,
  }) {
    return LocalizationState(
      translationServices: translationServices ?? this.translationServices,
      contentLanguage: contentLanguage ?? this.contentLanguage,
    );
  }
}
