import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/wot_configuration.dart';
import '../../../utils/utils.dart';

part 'wot_configuration_state.dart';

class WotConfigurationCubit extends Cubit<WotConfigurationState> {
  WotConfigurationCubit()
      : super(
          const WotConfigurationState(
            notifications: true,
            postActions: true,
            privateMessages: false,
            threshold: 5,
          ),
        ) {
    init();
  }

  late WotConfiguration conf;

  void init() {
    conf = nostrRepository
        .getWotConfiguration(
          currentSigner!.getPublicKey(),
        )
        .copyWith();

    emit(
      state.copyWith(
        notifications: conf.notifications,
        postActions: conf.postActions,
        privateMessages: conf.privateMessages,
        threshold: conf.threshold,
      ),
    );
  }

  bool? getSettingsStatus() {
    final allEnabled =
        state.notifications && state.postActions && state.privateMessages;

    final allDisabled =
        !state.notifications && !state.postActions && !state.privateMessages;

    if (allEnabled) {
      return true;
    }

    if (allDisabled) {
      return false;
    }

    return null;
  }

  void updateSettings({
    double? threshold,
    bool? notifications,
    bool? postActions,
    bool? privateMessages,
  }) {
    emit(
      state.copyWith(
        threshold: threshold,
        notifications: notifications,
        postActions: postActions,
        privateMessages: privateMessages,
      ),
    );
  }

  @override
  Future<void> close() {
    nostrRepository.setWotConfiguration(
      pubkey: conf.pubkey,
      threshold: state.threshold,
      notifications: state.notifications,
      postActions: state.postActions,
      privateMessages: state.privateMessages,
    );

    if (conf.notifications != state.notifications) {
      notificationsCubit.initNotifications();
    }

    return super.close();
  }
}
