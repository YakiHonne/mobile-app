import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import 'utils.dart';

class BotToastUtils {
  static int toastDuration = 3;

  static void showUnreachableRelaysError() {
    BotToast.showText(
      text: t.relaysNotReached.capitalizeFirst(),
      contentColor: kRed,
      textStyle: const TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static void showError(String message) {
    BotToast.showText(
      duration: Duration(seconds: toastDuration),
      text: message,
      contentColor: kRed,
      textStyle: const TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static void showInformation(String message) {
    BotToast.showText(
      duration: Duration(seconds: toastDuration),
      text: message,
      contentColor: kBlue,
      textStyle: const TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static void showSuccess(String message) {
    BotToast.showText(
      text: message,
      duration: Duration(seconds: toastDuration),
      contentColor: kGreen,
      textStyle: const TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }

  static void showWarning(String message) {
    BotToast.showText(
      text: message,
      duration: Duration(seconds: toastDuration),
      contentColor: kMainColor,
      textStyle: const TextStyle(
        color: kWhite,
        fontSize: 12,
      ),
    );
  }
}
