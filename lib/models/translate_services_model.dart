// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../utils/utils.dart';

final translationServicesNames = [
  'LibreTranslate',
  'DeepL',
  'translate.nostr.wine',
];

final translationServicesInfo = {
  TranslationsServices.deeplPro.name: 'https://api.deepl.com/v2/translate',
  TranslationsServices.deeplFree.name:
      'https://api-free.deepl.com/v2/translsate',
  TranslationsServices.wineTranslate.name:
      'https://translate.nostr.wine/translate',
  TranslationsServices.libreTranslateFree.name:
      'https://translator.yakihonne.com/translate',
  TranslationsServices.libreTranslatePro.name:
      'https://libretranslate.com/translate',
};

final translationServicesApiUrls = {
  TranslationsServices.deeplPro.name: 'https://www.deepl.com/en/products/api',
  TranslationsServices.deeplFree.name: 'https://www.deepl.com/en/products/api',
  TranslationsServices.wineTranslate.name: 'https://translate.nostr.wine',
  TranslationsServices.libreTranslateFree.name:
      'https://portal.libretranslate.com',
  TranslationsServices.libreTranslatePro.name:
      'https://portal.libretranslate.com',
};

// Base sealed class for service identification
abstract class ServiceIdentifier extends Equatable {
  const ServiceIdentifier();

  String get identifier;
  bool get isCustom;
}

// Built-in services
class BuiltInService extends ServiceIdentifier {
  final TranslationsServices service;

  const BuiltInService(this.service);

  @override
  String get identifier => service.name;

  @override
  bool get isCustom => false;

  @override
  List<Object?> get props => [service];
}

// Custom services
class CustomService extends ServiceIdentifier {
  final String serviceId;

  const CustomService(this.serviceId);

  @override
  String get identifier => serviceId;

  @override
  bool get isCustom => true;

  @override
  List<Object?> get props => [serviceId];
}

class TranslationServices extends Equatable {
  final ServiceIdentifier selectedTranslationService;
  final Map<String, String> apiKeys;
  final Map<String, String> customServices;

  const TranslationServices({
    required this.selectedTranslationService,
    required this.apiKeys,
    required this.customServices,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'selectedTranslationService': selectedTranslationService.identifier,
      'isCustomService': selectedTranslationService.isCustom,
      'apiKeys': apiKeys,
      'customServices': customServices,
    };
  }

  factory TranslationServices.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return const TranslationServices(
        selectedTranslationService: BuiltInService(
          TranslationsServices.libreTranslateFree,
        ),
        apiKeys: {},
        customServices: {},
      );
    } else {
      final serviceId = map['selectedTranslationService'] as String;
      final isCustom = map['isCustomService'] as bool? ?? false;

      ServiceIdentifier selectedService;
      if (isCustom) {
        selectedService = CustomService(serviceId);
      } else {
        final enumValue = TranslationsServices.values.firstWhere(
          (element) => element.name == serviceId,
          orElse: () => TranslationsServices.libreTranslateFree,
        );
        selectedService = BuiltInService(enumValue);
      }

      return TranslationServices(
        selectedTranslationService: selectedService,
        apiKeys: Map<String, String>.from(map['apiKeys'] as Map),
        customServices: Map<String, String>.from(
          map['customServices'] as Map? ?? {},
        ),
      );
    }
  }

  String toJson() => json.encode(toMap());

  factory TranslationServices.fromJson(String source) =>
      TranslationServices.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [
        selectedTranslationService,
        apiKeys,
        customServices,
      ];

  TranslationServices copyWith({
    ServiceIdentifier? selectedTranslationService,
    Map<String, String>? apiKeys,
    Map<String, String>? customServices,
  }) {
    return TranslationServices(
      selectedTranslationService:
          selectedTranslationService ?? this.selectedTranslationService,
      apiKeys: apiKeys ?? this.apiKeys,
      customServices: customServices ?? this.customServices,
    );
  }

  // Helper methods for easier usage
  bool get isUsingCustomService => selectedTranslationService.isCustom;

  TranslationsServices? get builtInService =>
      selectedTranslationService is BuiltInService
          ? (selectedTranslationService as BuiltInService).service
          : null;

  String? get customServiceName => selectedTranslationService is CustomService
      ? (selectedTranslationService as CustomService).serviceId
      : null;

  String get getSelectedTsTitle => selectedTranslationService is CustomService
      ? getCustomUrlName(
          (selectedTranslationService as CustomService).serviceId,
        )
      : builtInService!.name;

  static String getCustomUrlName(String url) {
    final uri = Uri.parse(url);

    return uri.host;
  }

  String? get getCurrentCustomServiceUrl {
    final id = selectedTranslationService is CustomService
        ? (selectedTranslationService as CustomService).serviceId
        : null;

    if (id != null) {
      return customServices[id];
    }

    return null;
  }
}
