import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../logic/bot_utils_loading_progress_cubit/bot_utils_loading_progress_cubit.dart';
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

  static CancelFunc showLoading() {
    final ctx = nostrRepository.currentContext();

    return BotToast.showCustomLoading(
      align: Alignment.center,
      onClose: () {
        botUtilsLoadingProgressCubit.emitStatus('');
      },
      toastBuilder: (cancelFunc) {
        return BlocBuilder<BotUtilsLoadingProgressCubit,
            BotUtilsLoadingProgressState>(
          builder: (context, state) {
            return UnconstrainedBox(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: state.status.isEmpty ? 70 : 100,
                width: state.status.isEmpty ? 70 : 100,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).cardColor,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  border: Border.all(
                    color: Theme.of(ctx).dividerColor,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  spacing: kDefaultPadding / 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpinKitCircle(
                      color: Theme.of(ctx).primaryColor,
                      size: 25,
                    ),
                    if (state.status.isNotEmpty)
                      Text(
                        state.status,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
