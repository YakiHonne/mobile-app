import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'crashlytics_state.dart';

class CrashlyticsCubit extends Cubit<CrashlyticsState> {
  CrashlyticsCubit()
      : super(
          CrashlyticsState(
            isCrashlyticsEnabled:
                localDatabaseRepository.getCrashlyticsDataCollection(),
            automaticCachePurge:
                localDatabaseRepository.getAutomaticCachePurge(),
            dataCacheSize: 0.0,
            mediaCacheSize: 0.0,
            isDataCacheToggled: false,
            isMediaCacheToggled: false,
          ),
        ) {
    init();
  }

  Future<void> init() async {
    Future.delayed(const Duration(seconds: 5)).then(
      (value) async {
        final res = await Future.wait([
          nc.db.getDatabaseSizeInMB(),
          getCachedMediaSizeInMB(),
        ]);

        final dataSize = res[0];
        final mediaSize = res[1];

        if (state.automaticCachePurge) {
          await purgeCache(
            dataCheckBox: dataSize > cacheMaxSize,
            mediaCheckBox: mediaSize > cacheMaxSize,
          );
        } else {
          emit(state.copyWith(
            dataCacheSize: dataSize,
            mediaCacheSize: mediaSize,
          ));
        }
      },
    );
  }

  void setCrashlyticsStatus(bool status) {
    localDatabaseRepository.setAnalyticsDataCollection(status);
    nostrRepository.isCrashlyticsEnabled = status;

    if (!isClosed) {
      emit(
        state.copyWith(
          isCrashlyticsEnabled: status,
        ),
      );
    }
  }

  Future<void> setAutomaticCachePurge(bool status) async {
    localDatabaseRepository.setAutomaticCachePurge(status);
    emit(
      state.copyWith(automaticCachePurge: status),
    );

    if (status) {
      await purgeCache(
        dataCheckBox: state.dataCacheSize > cacheMaxSize,
        mediaCheckBox: state.mediaCacheSize > cacheMaxSize,
      );
    }
  }

  void toggleSelection({bool? isDataCacheToggled, bool? isMediaCacheToggled}) {
    emit(state.copyWith(
      isDataCacheToggled: isDataCacheToggled,
      isMediaCacheToggled: isMediaCacheToggled,
    ));
  }

  Future<void> purgeCache({
    required bool dataCheckBox,
    required bool mediaCheckBox,
    Function()? onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

    await Future.wait([
      if (dataCheckBox) NostrFunctionsRepository.clearCache(),
      if (mediaCheckBox) clearDiskCachedImages(),
    ]);

    localDatabaseRepository.setCachePopup(true);
    getSizes();
    cancel.call();
    onSuccess?.call();
  }

  Future<void> getSizes() async {
    final res = await Future.wait([
      nc.db.getDatabaseSizeInMB(),
      getCachedMediaSizeInMB(),
    ]);

    final dataSize = res[0];
    final mediaSize = res[1];

    emit(state.copyWith(
      dataCacheSize: dataSize,
      mediaCacheSize: mediaSize,
      isDataCacheToggled: false,
      isMediaCacheToggled: false,
    ));
  }
}
