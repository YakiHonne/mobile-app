import 'dart:math';

import 'package:flutter/material.dart';

extension StringExtension on String {
  String nineCharacters() {
    return length >= 10 ? substring(0, 9) : this;
  }

  String capitalize() {
    return isNotEmpty
        ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
        : '';
  }

  String capitalizeFirst() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }

  String removeFirstCharacter() {
    return isNotEmpty ? substring(1) : '';
  }

  String lowerize() {
    return isNotEmpty ? '${this[0].toLowerCase()}${substring(1)}' : '';
  }

  String hexToAscii() {
    return List.generate(
      length ~/ 2,
      (i) => String.fromCharCode(
        int.parse(substring(i * 2, (i * 2) + 2), radix: 16),
      ),
    ).join();
  }

  String removeLastBackSlashes() {
    if (isEmpty) {
      return this;
    }

    final List<String> result = characters.toList();

    for (int i = length - 1; i >= 0; i--) {
      if (result[i] == '/') {
        result.removeAt(i);
      } else {
        return result.join();
      }
    }

    return result.join();
  }

  double getAspectRatio() {
    final List<String> parts = split(RegExp(r'[:/]'));

    if (parts.length == 2) {
      final int width = int.parse(parts[0]);
      final int height = int.parse(parts[1]);

      return width / height;
    } else {
      return 1;
    }
  }

  bool get isRemoteURL => RegExp(r'https?:\/\/').hasMatch(this);
  bool get isFileURL => RegExp(r'file:\/\/').hasMatch(toLowerCase());

  String? getFileName({bool withExtension = true}) {
    try {
      final Uri uri = Uri.parse(this);
      final path = uri.path;
      final fileName = path.split('/').last;
      if (!withExtension && fileName.contains('.')) {
        return fileName.substring(0, fileName.lastIndexOf('.'));
      }
      return fileName;
    } catch (_) {
      return null;
    }
  }

  String getFileExtension() {
    return getFileName()?.split('.').lastOrNull ?? '';
  }

  Locale toLocale() {
    final parts = split(RegExp(r'[_-]'));

    if (parts.length == 1) {
      return Locale(parts[0]);
    } else if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      throw FormatException('Invalid locale format: $this');
    }
  }
}

extension ColorExtension on Color {
  String toHex() {
    final aU = (a * 255).round();
    final rU = (r * 255).round();
    final gU = (g * 255).round();
    final bU = (b * 255).round();
    final v = (aU << 24) | (rU << 16) | (gU << 8) | bU;

    final res = '#${v.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    return res.replaceFirst('FF', '');
  }
}

extension IntegersParsing on int {
  String formattedSeconds() {
    final int sec = this % 60;
    final int min = (this / 60).floor();
    final String minute = min.toString().length <= 1 ? '0$min' : '$min';
    final String second = sec.toString().length <= 1 ? '0$sec' : '$sec';
    return '$minute : $second';
  }

  bool isOlderThan24Hours({int? v}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final referenceTime = v ?? now;
    final threshold = referenceTime - (24 * 60 * 60);

    return this < threshold;
  }

  bool isNewerThan1Month({int? v}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final referenceTime = v ?? now;

    final threshold = referenceTime - (24 * 60 * 60 * 30.44).round();
    return this >= threshold;
  }

  bool isNewerThan3Months({int? v}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final referenceTime = v ?? now;

    final threshold = referenceTime - (24 * 60 * 60 * 30.44 * 3).round();
    return this >= threshold;
  }

  bool isNewerThan6Months({int? v}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final referenceTime = v ?? now;

    final threshold = referenceTime - (24 * 60 * 60 * 30.44 * 6).round();
    return this >= threshold;
  }

  bool isNewerThan1Year({int? v}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final referenceTime = v ?? now;

    final threshold = referenceTime - (24 * 60 * 60 * 365.25).round();
    return this >= threshold;
  }
}

extension LowerCaseList on List<String> {
  void toLowerCase() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].toLowerCase();
    }
  }

  List<String> toLowerCaseTrim() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].toLowerCase();
      this[i].trim();
    }

    return this;
  }
}

extension UppderCaseList on List<String> {
  void toUpperCase() {
    for (int i = 0; i < length; i++) {
      this[i] = this[i].capitalize();
    }
  }
}

extension ImageExtension on num {
  int cacheSize(BuildContext context) {
    return (this * MediaQuery.of(context).devicePixelRatio).round();
  }
}

extension DurationExtensions on Duration {
  num toYearsMonthsDaysString() {
    final months = (inDays ~/ 365) ~/ 30;

    return months;
  }
}

extension DateTimeExtension on DateTime {
  String formattedDate() {
    final now = DateTime.now();

    // If the same day
    if (now.year == year && now.month == month && now.day == day) {
      final duration = now.difference(this);

      if (duration.inHours > 0) {
        return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
      } else if (duration.inMinutes > 0) {
        return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    }

    // If the same year but different day
    if (now.year == year) {
      return '$month/$day';
    }

    // If it's a different year
    return '$year/$month/$day';
  }

  bool isOlderThan24Hours({int? v}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final referenceTime = v ?? now;
    final threshold = referenceTime - (24 * 60 * 60);

    return (millisecondsSinceEpoch ~/ 1000) < threshold;
  }
}

extension GetByKeyIndex on Map {
  dynamic elementAt(int index) => values.elementAt(index);
}

Random _random = Random();

String randomHexString(int length) {
  final StringBuffer sb = StringBuffer();
  for (var i = 0; i < length; i++) {
    sb.write(_random.nextInt(16).toRadixString(16));
  }
  return sb.toString();
}
