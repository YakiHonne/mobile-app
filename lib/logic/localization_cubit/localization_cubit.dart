import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/translate_services_model.dart';
import '../../repositories/http_functions_repository.dart';
import '../../utils/utils.dart';

part 'localization_state.dart';

// =============================================================================
// LOCALIZATION CUBIT: Manages app localization and translation services
// =============================================================================
class LocalizationCubit extends Cubit<LocalizationState> {
  // =============================================================================
  // INITIALIZATION
  // =============================================================================
  LocalizationCubit()
      : super(
          const LocalizationState(
            translationServices: TranslationServices(
              selectedTranslationService:
                  BuiltInService(TranslationsServices.libreTranslateFree),
              customServices: {},
              apiKeys: {},
            ),
          ),
        );

  // =============================================================================
  // LOCALE MANAGEMENT
  // =============================================================================

  /// Set the app language and persist the choice.
  Future<void> setLanguage(Locale locale) async {
    await setLocale(locale);
    localDatabaseRepository.setLanguage(language: locale.languageCode);
  }

  /// Initialize translation services and locale.
  Future<void> init() async {
    await initTranslationService();
    await initLocale();
    // listenToLocaleChanges();
  }

  /// Initialize the locale from storage or system.
  Future<void> initLocale() async {
    final lang = await localDatabaseRepository.getLanguage();
    Locale updatedLocale;
    if (lang == null) {
      final dc = WidgetsBinding.instance.platformDispatcher.locale.languageCode
          .split('_')
          .first
          .toLocale();
      updatedLocale = dc;
      localDatabaseRepository.setLanguage(language: updatedLocale.languageCode);
    } else {
      updatedLocale = lang.toLocale();
    }
    await setLocale(updatedLocale);
  }

  /// Set the app's active locale.
  Future<void> setLocale(Locale setLocale) async {
    final appLocale = AppLocale.values.firstWhere(
      (e) => e.languageCode == setLocale.languageCode,
      orElse: () => AppLocale.en,
    );
    await LocaleSettings.setLocale(appLocale);
  }

  // =============================================================================
  // TRANSLATION SERVICE MANAGEMENT
  // =============================================================================

  /// Initialize translation service from storage or defaults.
  Future<void> initTranslationService() async {
    TranslationServices translationServices;
    final ts = await localDatabaseRepository.getTranslateServices();
    if (ts == null) {
      translationServices = const TranslationServices(
        selectedTranslationService: BuiltInService(
          TranslationsServices.libreTranslateFree,
        ),
        apiKeys: {},
        customServices: {},
      );
      await localDatabaseRepository.setTranslateServices(
        ts: translationServices.toJson(),
      );
    } else {
      translationServices = TranslationServices.fromJson(ts);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          translationServices: translationServices,
        ),
      );
    }
  }

  /// Set the translation service and optional API key, then persist.
  Future<void> setDefaultTranslationService({
    required TranslationsServices ts,
    String? apiKey,
  }) async {
    final oldTs = state.translationServices;
    Map<String, String>? newKeys;
    if (apiKey != null) {
      newKeys = Map<String, String>.from(oldTs.apiKeys);
      newKeys[ts.name] = apiKey;
    }
    final translationServices = oldTs.copyWith(
      selectedTranslationService: BuiltInService(ts),
      apiKeys: newKeys,
    );
    await localDatabaseRepository.setTranslateServices(
      ts: translationServices.toJson(),
    );
    if (!isClosed) {
      emit(
        state.copyWith(
          translationServices: translationServices,
        ),
      );
    }
  }

  Future<void> setCustomTranslationService({
    required String url,
    required bool isFree,
    String? apiKey,
  }) async {
    final key = 'custom-${isFree ? "free" : "pro"}-$url';
    final oldTs = state.translationServices;
    Map<String, String>? newKeys;
    final customServices = Map<String, String>.from(oldTs.customServices);
    customServices[key] = url;

    if (apiKey != null) {
      newKeys = Map<String, String>.from(oldTs.apiKeys);
      newKeys[key] = apiKey;
    }

    final translationServices = oldTs.copyWith(
      selectedTranslationService: CustomService(key),
      apiKeys: newKeys,
      customServices: customServices,
    );

    await localDatabaseRepository.setTranslateServices(
      ts: translationServices.toJson(),
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          translationServices: translationServices,
        ),
      );
    }
  }

  Future<void> deleteCustomTranslationService({
    required String key,
  }) async {
    final oldTs = state.translationServices;
    final newKeys = Map<String, String>.from(oldTs.apiKeys)..remove(key);
    final customServices = Map<String, String>.from(oldTs.customServices)
      ..remove(key);

    final translationServices = oldTs.copyWith(
      selectedTranslationService: const BuiltInService(
        TranslationsServices.libreTranslateFree,
      ),
      apiKeys: newKeys,
      customServices: customServices,
    );

    await localDatabaseRepository.setTranslateServices(
      ts: translationServices.toJson(),
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          translationServices: translationServices,
        ),
      );
    }
  }

  // =============================================================================
  // TRANSLATION LOGIC
  // =============================================================================

  /// Translate content using the selected translation service.
  Future<MapEntry<bool, String>> translateContent({
    required String content,
  }) async {
    final lc = LocaleSettings.currentLocale.languageCode;

    if (state.translationServices.isUsingCustomService) {
      final tServices = state.translationServices.customServiceName!;
      final apiKey = state.translationServices.apiKeys[tServices];
      final url = state.translationServices.getCurrentCustomServiceUrl;

      if (url == null) {
        return MapEntry(
          false,
          t.errorMissingKey.capitalizeFirst(),
        );
      }

      return HttpFunctionsRepository.customTranslate(
        content: content,
        targetLang: lc,
        url: url,
        apiKey: apiKey,
      );
    } else {
      final tServices = state.translationServices.builtInService!;
      final apiKey = state.translationServices.apiKeys[tServices.name];
      if (tServices != TranslationsServices.libreTranslateFree &&
          (apiKey == null || apiKey.isEmpty)) {
        return MapEntry(
          false,
          t.errorMissingKey.capitalizeFirst(),
        );
      }

      final url = translationServicesInfo[tServices.name]!;

      if (tServices == TranslationsServices.deeplFree ||
          tServices == TranslationsServices.deeplPro) {
        return HttpFunctionsRepository.translateWithDeepL(
          content: content,
          targetLang: lc,
          url: url,
          apiKey: apiKey!,
        );
      } else if (tServices == TranslationsServices.libreTranslateFree ||
          tServices == TranslationsServices.libreTranslatePro) {
        return HttpFunctionsRepository.customTranslate(
          content: content,
          targetLang: lc,
          url: url,
          apiKey: apiKey,
        );
      } else {
        return HttpFunctionsRepository.translateWithWine(
          content: content,
          targetLang: lc,
          url: url,
          apiKey: apiKey!,
        );
      }
    }
  }
}
