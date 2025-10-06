// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'localization_cubit.dart';

class LocalizationState extends Equatable {
  final TranslationServices translationServices;

  const LocalizationState({
    required this.translationServices,
  });

  @override
  List<Object> get props => [translationServices];

  LocalizationState copyWith({
    TranslationServices? translationServices,
  }) {
    return LocalizationState(
      translationServices: translationServices ?? this.translationServices,
    );
  }
}
