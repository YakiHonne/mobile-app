// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../repositories/http_functions_repository.dart';
import '../utils/bot_toast_util.dart';
import '../utils/utils.dart';
import 'flash_news_model.dart';

class SWAutoSaveModel {
  final String id;
  final Map<String, dynamic> content;
  final String title;
  final int createdAt;

  SWAutoSaveModel({
    required this.id,
    required this.content,
    required this.title,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'content': content,
      'title': title,
      'createdAt': createdAt,
    };
  }

  factory SWAutoSaveModel.fromMap(Map<String, dynamic> map) {
    return SWAutoSaveModel(
      id: map['id'] as String,
      content: map['content'],
      title: map['title'] as String,
      createdAt: map['createdAt'] as int? ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory SWAutoSaveModel.fromJson(String source) =>
      SWAutoSaveModel.fromMap(json.decode(source) as Map<String, dynamic>);

  SWAutoSaveModel copyWith({
    String? id,
    Map<String, dynamic>? content,
    String? title,
    int? createdAt,
  }) {
    return SWAutoSaveModel(
      id: id ?? this.id,
      content: content ?? this.content,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SmartWidget extends Equatable implements BaseEventModel {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final String pubkey;
  final String identifier;
  final String client;
  final String title;
  final List<String> keywords;
  final String icon;
  final String image;
  final SWType type;
  final SmartWidgetBox smartWidgetBox;
  final String stringifiedEvent;

  const SmartWidget({
    required this.id,
    required this.createdAt,
    required this.pubkey,
    required this.identifier,
    required this.client,
    required this.title,
    required this.keywords,
    required this.icon,
    required this.image,
    required this.type,
    required this.smartWidgetBox,
    required this.stringifiedEvent,
  });

  String getNaddr() {
    final List<int> charCodes = identifier.runes.toList();
    final special = charCodes.map((code) => code.toRadixString(16)).join();

    return Nip19.encodeShareableEntity(
      'naddr',
      special,
      [],
      pubkey,
      EventKind.SMART_WIDGET_ENH,
    );
  }

  Future<String> getNaddrWithRelays() async {
    final List<int> charCodes = identifier.runes.toList();
    final special = charCodes.map((code) => code.toRadixString(16)).join();
    final relays =
        await getEventSeenOnRelays(id: identifier, isReplaceable: true);

    return Nip19.encodeShareableEntity(
      'naddr',
      special,
      relays,
      pubkey,
      EventKind.SMART_WIDGET_ENH,
    );
  }

  String aTag() {
    return '${EventKind.SMART_WIDGET_ENH}:$pubkey:$identifier';
  }

  factory SmartWidget.fromEvent(Event event) {
    String image = '';
    SmartWidgetInputField? inputField;
    final buttons = <SmartWidgetButton>[];
    String identifier = '';
    String client = '';
    SWType type = SWType.basic;
    String icon = '';
    final keywords = <String>[];
    final createdAt =
        DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000);

    for (final tag in event.tags) {
      if (tag.first == 'image' && tag.length > 1) {
        image = tag[1];
      } else if (tag.first == 'button' && tag.length > 3) {
        buttons.add(
          SmartWidgetButton(
            text: tag[1],
            type: SWBType.values.firstWhere(
              (element) => element.name.toLowerCase() == tag[2].toLowerCase(),
              orElse: () => SWBType.Redirect,
            ),
            url: tag[3],
            id: uuid.v4(),
          ),
        );
      } else if (tag.first == 'input' && tag.length > 1) {
        inputField = SmartWidgetInputField(placeholder: tag[1]);
      } else if (tag.first == 'd' && tag.length > 1 && identifier.isEmpty) {
        identifier = tag[1].trim();
      } else if (tag.first == 'client' && tag.length > 1) {
        client = tag[1];
      } else if (tag.first == 't' && tag.length > 1) {
        keywords.add(tag[1]);
      } else if (tag.first == 'l' && tag.length > 1) {
        type = SWType.values.firstWhere(
          (element) => element.name == tag[1],
          orElse: () => SWType.basic,
        );
      } else if (tag.first == 'icon' && tag.length > 1) {
        icon = tag[1];
      }
    }

    return SmartWidget(
      id: event.id,
      createdAt: createdAt,
      client: client,
      pubkey: event.pubkey,
      title: event.content,
      identifier: identifier,
      type: type,
      icon: icon,
      image: image,
      stringifiedEvent: event.toJsonString(),
      keywords: keywords,
      smartWidgetBox: SmartWidgetBox(
        image: SmartWidgetImage(url: image),
        inputField: inputField,
        buttons: buttons,
      ),
    );
  }

  String? getAppUrl() {
    final buttons = smartWidgetBox.buttons;

    if ((type == SWType.action || type == SWType.tool) &&
        buttons.isNotEmpty &&
        buttons.first.type == SWBType.App) {
      return buttons.first.url;
    }

    return null;
  }

  @override
  List<Object?> get props => [
        id,
        createdAt,
        pubkey,
        identifier,
        client,
        title,
        keywords,
        icon,
        type,
        smartWidgetBox,
        stringifiedEvent,
      ];

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'pubkey': pubkey,
      'identifier': identifier,
      'client': client,
      'title': title,
      'keywords': keywords,
      'type': type.name,
      'icon': icon,
      'image': image,
      'smartWidgetBox': smartWidgetBox.toMap(),
      'stringifiedEvent': stringifiedEvent,
    };
  }

  factory SmartWidget.fromMap(Map<String, dynamic> map) {
    return SmartWidget(
      id: map['id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      pubkey: map['pubkey'] as String,
      identifier: map['identifier'] as String,
      icon: map['icon'] as String,
      type: SWType.values.firstWhere(
        (element) => element.name == map['type'],
        orElse: () => SWType.basic,
      ),
      client: map['client'] as String,
      title: map['title'] as String,
      image: map['image'] as String? ?? '',
      stringifiedEvent: map['stringifiedEvent'] as String,
      keywords: List<String>.from(map['keywords'] as List? ?? []),
      smartWidgetBox:
          SmartWidgetBox.fromMap(map['smartWidgetBox'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory SmartWidget.fromJson(String source) =>
      SmartWidget.fromMap(json.decode(source) as Map<String, dynamic>);
}

abstract class SmartWidgetBoxComponent {
  SmartWidgetBoxComponent();
}

class SmartWidgetBox extends Equatable {
  final SmartWidgetImage image;
  final SmartWidgetInputField? inputField;
  final List<SmartWidgetButton> buttons;

  const SmartWidgetBox({
    required this.image,
    required this.buttons,
    this.inputField,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'image': image.toMap(),
      'inputField': inputField?.toMap(),
      'buttons': buttons.map((x) => x.toMap()).toList(),
    };
  }

  factory SmartWidgetBox.fromMap(Map<String, dynamic> map) {
    try {
      return SmartWidgetBox(
        image: SmartWidgetImage.fromMap(map['image'] as Map<String, dynamic>),
        inputField: map['inputField'] != null
            ? SmartWidgetInputField.fromMap(
                map['inputField'] as Map<String, dynamic>,
              )
            : null,
        buttons: List<SmartWidgetButton>.from(
          (map['buttons'] as List? ?? []).map<SmartWidgetButton?>(
            (x) => SmartWidgetButton.fromMap(x as Map<String, dynamic>),
          ),
        ),
      );
    } catch (e) {
      lg.i(e);
      return const SmartWidgetBox(
        image: SmartWidgetImage(url: ''),
        buttons: [],
      );
    }
  }

  String toJson() => json.encode(toMap());

  factory SmartWidgetBox.fromJson(String source) =>
      SmartWidgetBox.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [image, inputField, buttons];

  SmartWidgetBox copyWith({
    SmartWidgetImage? image,
    SmartWidgetInputField? inputField,
    List<SmartWidgetButton>? buttons,
  }) {
    return SmartWidgetBox(
      image: image ?? this.image,
      inputField: inputField,
      buttons: buttons ?? this.buttons,
    );
  }
}

class SmartWidgetImage extends Equatable implements SmartWidgetBoxComponent {
  final String url;

  const SmartWidgetImage({
    required this.url,
  });

  factory SmartWidgetImage.empty() {
    return const SmartWidgetImage(url: '');
  }

  SmartWidgetImage copyWith({
    String? url,
  }) {
    return SmartWidgetImage(
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'url': url,
    };
  }

  factory SmartWidgetImage.fromMap(Map<String, dynamic> map) {
    return SmartWidgetImage(
      url: map['url'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SmartWidgetImage.fromJson(String source) =>
      SmartWidgetImage.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [url];
}

class SmartWidgetInputField extends Equatable
    implements SmartWidgetBoxComponent {
  final String placeholder;

  const SmartWidgetInputField({
    required this.placeholder,
  });

  SmartWidgetInputField copyWith({
    String? placeHolder,
  }) {
    return SmartWidgetInputField(
      placeholder: placeHolder ?? placeholder,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'placeHolder': placeholder,
    };
  }

  factory SmartWidgetInputField.fromMap(Map<String, dynamic> map) {
    return SmartWidgetInputField(
      placeholder: map['placeHolder'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SmartWidgetInputField.fromJson(String source) =>
      SmartWidgetInputField.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [placeholder];
}

class ButtonFunctions {
  String type;
  String baseUrl;
  Set<String>? pubkeys;
  DateTime? time;
  DateTime? startsAt;
  DateTime? endsAt;
  String? lud16;

  ButtonFunctions({
    required this.type,
    required this.baseUrl,
    this.pubkeys,
    this.time,
    this.startsAt,
    this.endsAt,
    this.lud16,
  });

  factory ButtonFunctions.fromUrl(String url) {
    final uri = Uri.parse(url);
    final params = uri.queryParameters;

    final baseUrl = url.isEmpty ? '' : '${uri.origin}${uri.path}';

    final type = url.isEmpty
        ? postFunctionsMap.entries.first.key
        : postFunctionsMap.entries.firstWhere(
            (e) => e.value.contains(baseUrl),
            orElse: () {
              return postFunctionsMap.entries.first;
            },
          ).key;

    Set<String>? pubkeys;
    DateTime? time;
    DateTime? startsAt;
    DateTime? endsAt;
    String? lud16;

    for (final param in params.entries) {
      if (param.key == 'pubkey') {
        pubkeys ??= {};
        pubkeys.add(param.value);
      } else if (param.key == 'time') {
        time = DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(param.value) ?? 0) * 1000,
        );
      } else if (param.key == 'ends_at') {
        endsAt = DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(param.value) ?? 0) * 1000,
        );
      } else if (param.key == 'starts_at') {
        startsAt = DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(param.value) ?? 0) * 1000,
        );
      } else if (param.key == 'lud16') {
        lud16 = param.value;
      }
    }

    return ButtonFunctions(
      type: type,
      baseUrl: baseUrl,
      pubkeys: pubkeys,
      time: time,
      startsAt: startsAt,
      endsAt: endsAt,
      lud16: lud16,
    );
  }

  String currentUrl() {
    final uri = Uri.parse(baseUrl);

    final updateUri = uri.replace(
      queryParameters: {
        if (time != null) 'time': time!.toSecondsSinceEpoch().toString(),
        if (startsAt != null)
          'starts_at': startsAt!.toSecondsSinceEpoch().toString(),
        if (endsAt != null) 'ends_at': endsAt!.toSecondsSinceEpoch().toString(),
        if (lud16 != null) 'lud16': lud16,
        if (pubkeys != null)
          for (final pubkey in pubkeys!) ...{'pubkey': pubkey}
      },
    );

    return updateUri.toString();
  }

  bool checkValidity(BuildContext context) {
    if (shouldHaveTime() && time == null) {
      BotToastUtils.showError(context.t.countdownTime);
      return false;
    }

    if (shouldHaveLud16() && lud16 == null) {
      BotToastUtils.showError(context.t.lnMandatory);
      return false;
    }

    if (shouldHaveEndsAt() && endsAt == null) {
      BotToastUtils.showError(context.t.contentEndsDate);
      return false;
    }

    if (shouldHavePubkeys() && (pubkeys == null || pubkeys!.isEmpty)) {
      BotToastUtils.showError(context.t.pubkeysMandatory);
      return false;
    }

    return true;
  }

  bool requiresParams() {
    return postRequireParams.contains(baseUrl);
  }

  bool requiredInput() {
    return postRequireInput.contains(baseUrl);
  }

  bool shouldHaveParams() {
    if (requiresParams()) {
      if (baseUrl == postUrls[5] && time == null) {
        return true;
      }

      if (baseUrl == postUrls[10] && (lud16 == null || endsAt == null)) {
        return true;
      }

      if ((baseUrl == postUrls[12] || baseUrl == postUrls[13]) &&
          pubkeys == null) {
        return true;
      }
    }

    return false;
  }

  bool shouldHaveTime() {
    return requiresParams() && baseUrl == postUrls[5];
  }

  bool shouldHaveEndsAt() {
    return requiresParams() && baseUrl == postUrls[10];
  }

  bool shouldHaveLud16() {
    return requiresParams() && baseUrl == postUrls[10];
  }

  bool shouldHavePubkeys() {
    return requiresParams() &&
        (baseUrl == postUrls[12] || baseUrl == postUrls[13]);
  }

  ButtonFunctions addProfile(String pubkey) {
    final newPubkeys = Set<String>.from(pubkeys ?? {})..add(pubkey);

    return copyWith()..pubkeys = newPubkeys;
  }

  ButtonFunctions removeProfile(String pubkey) {
    final newPubkeys = Set<String>.from(pubkeys ?? {})..remove(pubkey);

    return copyWith()..pubkeys = newPubkeys.isEmpty ? null : newPubkeys;
  }

  ButtonFunctions copyWith({
    String? type,
    String? baseUrl,
    Set<String>? pubkeys,
    DateTime? time,
    DateTime? startsAt,
    DateTime? endsAt,
    String? lud16,
  }) {
    return ButtonFunctions(
      type: this.type,
      baseUrl: this.baseUrl,
      pubkeys: this.pubkeys,
      time: this.time,
      startsAt: this.startsAt,
      endsAt: this.endsAt,
      lud16: this.lud16,
    );
  }
}

class SmartWidgetButton extends Equatable implements SmartWidgetBoxComponent {
  final String text;
  final SWBType type;
  final String url;
  final String id;

  const SmartWidgetButton({
    required this.text,
    required this.type,
    required this.url,
    required this.id,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'text': text,
      'type': type.name,
      'url': url,
      'id': id,
    };
  }

  factory SmartWidgetButton.empty() {
    return SmartWidgetButton(
      text: gc.t.button.capitalizeFirst(),
      type: SWBType.Redirect,
      url: '',
      id: uuid.v4(),
    );
  }

  factory SmartWidgetButton.fromMap(Map<String, dynamic> map) {
    return SmartWidgetButton(
      text: map['text'] as String,
      type: SWBType.values.firstWhere(
        (element) => element.name == map['type'],
        orElse: () => SWBType.Redirect,
      ),
      url: map['url'] as String,
      id: map['id'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory SmartWidgetButton.fromJson(String source) =>
      SmartWidgetButton.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  List<Object?> get props => [text, type, url];

  SmartWidgetButton copyWith({
    String? text,
    SWBType? type,
    String? url,
    String? id,
  }) {
    return SmartWidgetButton(
      text: text ?? this.text,
      type: type ?? this.type,
      url: url ?? this.url,
      id: id ?? this.id,
    );
  }
}

List<SmartWidgetTemplate> getTemplates(List templates) => templates
    .map(
      (e) => SmartWidgetTemplate.fromMap(e),
    )
    .toList();

class SmartWidgetTemplate {
  final String path;
  final String thumbnail;
  final String title;

  SmartWidgetTemplate({
    required this.path,
    required this.thumbnail,
    required this.title,
  });

  Future<SmartWidget?> getCurrentSmartWidget() async {
    try {
      return HttpFunctionsRepository.postSmartWidget(
        url: '$swtUrl$path',
        text: '',
        aTag: '',
      );
    } catch (e) {
      lg.i(e);
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'path': path,
      'thumbnail': thumbnail,
      'title': title,
    };
  }

  factory SmartWidgetTemplate.fromMap(Map<String, dynamic> map) {
    return SmartWidgetTemplate(
      path: map['path'] as String,
      thumbnail: map['thumbnail'] as String,
      title: map['title'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory SmartWidgetTemplate.fromJson(String source) =>
      SmartWidgetTemplate.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AppSmartWidget extends Equatable {
  final String pubkey;
  final String title;
  final String url;
  final String icon;
  final String image;
  final String buttonTitle;
  final List<String> keywords;

  const AppSmartWidget({
    required this.pubkey,
    required this.title,
    required this.url,
    required this.icon,
    required this.image,
    required this.buttonTitle,
    required this.keywords,
  });

  AppSmartWidget copyWith({
    String? pubkey,
    String? title,
    String? url,
    String? icon,
    String? image,
    String? buttonTitle,
    List<String>? keywords,
  }) {
    return AppSmartWidget(
      pubkey: pubkey ?? this.pubkey,
      title: title ?? this.title,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      image: image ?? this.image,
      buttonTitle: buttonTitle ?? this.buttonTitle,
      keywords: keywords ?? this.keywords,
    );
  }

  factory AppSmartWidget.empty() {
    return const AppSmartWidget(
      pubkey: '',
      title: '',
      url: '',
      icon: '',
      image: '',
      buttonTitle: '',
      keywords: [],
    );
  }

  factory AppSmartWidget.fromMap(Map<String, dynamic> map) {
    final widget = map['widget'] ?? {};

    return AppSmartWidget(
      pubkey: map['pubkey'] as String? ?? '',
      title: widget['title'] as String? ?? '',
      url: widget['appUrl'] as String? ?? '',
      icon: widget['iconUrl'] as String? ?? '',
      image: widget['imageUrl'] as String? ?? '',
      buttonTitle: widget['buttonTitle'] as String? ?? '',
      keywords: List<String>.from(widget['tags'] as List? ?? []),
    );
  }

  factory AppSmartWidget.fromSmartWidget(SmartWidget? smartWidget) {
    if (smartWidget == null || smartWidget.type == SWType.basic) {
      return AppSmartWidget.empty();
    } else {
      final buttons = smartWidget.smartWidgetBox.buttons;

      if (buttons.isEmpty) {
        return AppSmartWidget.empty();
      }

      final b1 = buttons.first;

      return AppSmartWidget(
        pubkey: smartWidget.pubkey,
        title: smartWidget.title,
        url: b1.url,
        icon: smartWidget.icon,
        image: smartWidget.smartWidgetBox.image.url,
        buttonTitle: buttons.first.text,
        keywords: smartWidget.keywords,
      );
    }
  }

  bool isValid() {
    final valid = pubkey.isNotEmpty &&
        title.isNotEmpty &&
        url.isNotEmpty &&
        image.isNotEmpty &&
        buttonTitle.isNotEmpty;

    return valid;
  }

  @override
  List<Object?> get props => [
        pubkey,
        title,
        url,
        icon,
        image,
        buttonTitle,
        keywords,
      ];
}
