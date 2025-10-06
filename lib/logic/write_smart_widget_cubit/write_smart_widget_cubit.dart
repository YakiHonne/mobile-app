import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../models/smart_widgets_components.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
import '../../utils/utils.dart';

part 'write_smart_widget_state.dart';

class WriteSmartWidgetCubit extends Cubit<WriteSmartWidgetState> {
  WriteSmartWidgetCubit({
    required this.uuId,
    required this.backgroundColor,
    this.sm,
    this.isCloning,
    this.selectFirstSmartWidgetDraft,
  }) : super(
          WriteSmartWidgetState(
            isOnboarding: sm == null,
            smartWidgetPublishSteps: SmartWidgetPublishSteps.specifications,
            swType: sm?.type ?? SWType.basic,
            title:
                sm != null && isCloning != null && !isCloning ? sm.title : '',
            smartWidgetUpdate: true,
            keywords: sm?.keywords ?? [],
            appSmartWidget: AppSmartWidget.fromSmartWidget(sm),
            smartWidgetBox: sm?.smartWidgetBox ??
                SmartWidgetBox(
                  image: SmartWidgetImage.empty(),
                  buttons: [SmartWidgetButton.empty()],
                ),
            toggleDisplay: false,
            icon: sm?.icon ?? '',
          ),
        ) {
    final box = sm?.smartWidgetBox ??
        SmartWidgetBox(
          image: SmartWidgetImage.empty(),
          buttons: [
            SmartWidgetButton.empty(),
          ],
        );

    swAutoSaveModel = SWAutoSaveModel(
      id: uuid.v4(),
      title: sm != null && isCloning != null && !isCloning! ? sm!.title : '',
      content: box.toMap(),
      createdAt: currentUnixTimestampSeconds(),
    );

    if (selectFirstSmartWidgetDraft != null &&
        (nostrRepository.userDrafts?.smartWidgetsDraft.isNotEmpty ?? false)) {
      final id =
          nostrRepository.userDrafts?.smartWidgetsDraft.entries.first.key;

      loadSMAutoSaveModel(id!);
    }
  }

  String uuId;
  String backgroundColor;
  SmartWidget? sm;
  bool? isCloning;
  String? draftId;
  bool? selectFirstSmartWidgetDraft;
  late SWAutoSaveModel swAutoSaveModel;

  void setSwAutoSaveModel(SWAutoSaveModel swAutoSaveModel) {
    this.swAutoSaveModel = swAutoSaveModel;

    final box = SmartWidgetBox.fromMap(
      swAutoSaveModel.content,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          title: swAutoSaveModel.title,
          isOnboarding: false,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }
  }

  void loadSMAutoSaveModel(String id) {
    final stringifiedSw = nostrRepository.userDrafts?.smartWidgetsDraft[id];

    final swd = stringifiedSw != null && stringifiedSw.isNotEmpty
        ? SWAutoSaveModel.fromJson(stringifiedSw)
        : null;

    swAutoSaveModel = swd ?? swAutoSaveModel;

    final box = SmartWidgetBox.fromMap(
      swAutoSaveModel.content,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          title: swAutoSaveModel.title,
          isOnboarding: false,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }
  }

  void setImage(String icon) {
    if (!isClosed) {
      emit(
        state.copyWith(icon: icon),
      );
    }
  }

  void deleteSmartWidgetAutoSaveModel() {
    if (!isClosed) {
      emit(
        state.copyWith(
          title: '',
        ),
      );
    }

    nostrRepository.saveSmartWidgetDraft(swsm: swAutoSaveModel);

    BotToastUtils.showSuccess(
      t.autoSavedSMdeleted.capitalizeFirst(),
    );
  }

  void addKeyword(String keyword) {
    if (!isClosed) {
      emit(
        state.copyWith(
          keywords: [
            ...state.keywords,
            keyword,
          ],
        ),
      );
    }
  }

  void deleteKeyword(String keyword) {
    final keywords = List<String>.from(state.keywords);
    keywords.remove(keyword);

    if (!isClosed) {
      emit(
        state.copyWith(keywords: keywords),
      );
    }
  }

  void setType(SWType type) {
    if (!isClosed) {
      emit(
        state.copyWith(
          swType: type,
        ),
      );
    }
  }

  Future<void> processAppSmartWidget({
    required String url,
    required Function() onFailed,
    required Function() onSuccess,
  }) async {
    final appSmartWidget = await HttpFunctionsRepository.getAppSmartWidget(
      url,
    );

    if (appSmartWidget == null || !appSmartWidget.isValid()) {
      onFailed.call();
    } else {
      onSuccess.call();

      emit(
        state.copyWith(
          appSmartWidget: appSmartWidget,
          icon: appSmartWidget.icon,
          title: appSmartWidget.title,
          keywords: appSmartWidget.keywords,
        ),
      );
    }
  }

  void resetAppSmartWidget() {
    if (!isClosed) {
      emit(
        state.copyWith(
          appSmartWidget: AppSmartWidget.empty(),
        ),
      );
    }
  }

  void setTitle(String title) {
    if (!isClosed) {
      emit(
        state.copyWith(
          title: title,
        ),
      );
    }

    swAutoSaveModel = swAutoSaveModel.copyWith(
      title: title,
      createdAt: currentUnixTimestampSeconds(),
    );

    nostrRepository.saveSmartWidgetDraft(swsm: swAutoSaveModel);
  }

  void setOnboardingOff() {
    if (!isClosed) {
      emit(
        state.copyWith(
          isOnboarding: false,
        ),
      );
    }
  }

  void setSmartWidgetContainer(SmartWidgetBox smartWidgetBox) {
    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetUpdate: !state.smartWidgetUpdate,
          smartWidgetBox: smartWidgetBox,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void setFramePublishStep(SmartWidgetPublishSteps step) {
    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetPublishSteps: step,
        ),
      );
    }
  }

  void updateImageUrl(String url) {
    final box = state.smartWidgetBox.copyWith(
      image: SmartWidgetImage(url: url),
      buttons: state.smartWidgetBox.buttons,
      inputField: state.smartWidgetBox.inputField,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void addInputField() {
    final box = state.smartWidgetBox.copyWith(
      inputField: SmartWidgetInputField(
        placeholder: nostrRepository.currentContext().t.placeholder,
      ),
      buttons: state.smartWidgetBox.buttons,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void updateInputPlaceholder(String placeHolder) {
    final box = state.smartWidgetBox.copyWith(
      inputField: SmartWidgetInputField(
        placeholder: placeHolder,
      ),
      buttons: state.smartWidgetBox.buttons,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void deleteInputField() {
    final box = state.smartWidgetBox.copyWith(
      buttons: state.smartWidgetBox.buttons,
      image: state.smartWidgetBox.image,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void addButton() {
    final buttons = state.smartWidgetBox.buttons;

    final box = state.smartWidgetBox.copyWith(
      buttons: buttons.length < 6
          ? [
              ...buttons,
              SmartWidgetButton(
                text: gc.t.button.capitalizeFirst(),
                type: SWBType.Redirect,
                url: '',
                id: uuid.v4(),
              ),
            ]
          : null,
      inputField: state.smartWidgetBox.inputField,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void moveButton({
    required String id,
    required bool moveRight,
  }) {
    final buttons = List<SmartWidgetButton>.of(
      state.smartWidgetBox.buttons,
    );

    final index = buttons.indexWhere((button) => button.id == id);
    if (index == -1) {
      return;
    }

    final newIndex = moveRight ? index + 1 : index - 1;
    if (newIndex < 0 || newIndex >= buttons.length) {
      return;
    }

    final temp = buttons[index];
    buttons[index] = buttons[newIndex];
    buttons[newIndex] = temp;

    final box = state.smartWidgetBox.copyWith(
      buttons: buttons,
      inputField: state.smartWidgetBox.inputField,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void updateButton(String id, SmartWidgetButton newButton) {
    final buttons = List<SmartWidgetButton>.of(
      state.smartWidgetBox.buttons,
    );

    final index = buttons.indexWhere((button) => button.id == id);
    if (index == -1) {
      return;
    }

    buttons[index] = newButton;

    final box = state.smartWidgetBox.copyWith(
      buttons: buttons,
      inputField: state.smartWidgetBox.inputField,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  void deleteButton(String id) {
    final buttons = state.smartWidgetBox.buttons;
    if (buttons.isEmpty) {
      return;
    }

    // Find the index of the button with the given id
    final index = buttons.indexWhere((button) => button.id == id);
    if (index == -1) {
      // Button not found
      return;
    }

    final bs = List<SmartWidgetButton>.from(buttons)..removeAt(index);
    final box = state.smartWidgetBox.copyWith(
      buttons: bs.isEmpty ? null : bs,
      inputField: state.smartWidgetBox.inputField,
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          smartWidgetBox: box,
          smartWidgetUpdate: !state.smartWidgetUpdate,
        ),
      );
    }

    updateContainerAutoSave();
  }

  Future<void> uploadMediaAndSend({
    required File file,
    required Function(String) onSuccess,
  }) async {
    final cancel = BotToast.showLoading();

    final mediaLink = (await mediaServersCubit.uploadMedia(file: file))['url'];

    if (mediaLink != null) {
      cancel.call();
      onSuccess.call(mediaLink);
    } else {
      cancel.call();
      BotToastUtils.showError(
        t.errorUploadingMedia.capitalizeFirst(),
      );
    }
  }

  void updateContainerAutoSave() {
    swAutoSaveModel = swAutoSaveModel.copyWith(
      content: state.smartWidgetBox.toMap(),
      createdAt: currentUnixTimestampSeconds(),
    );

    nostrRepository.saveSmartWidgetDraft(swsm: swAutoSaveModel);
  }

  Future<void> setSmartWidget({
    required EventSigner signer,
    required Function(SmartWidget) onSuccess,
  }) async {
    if (state.title.trim().isEmpty) {
      BotToastUtils.showError(gc.t.useValidTitle);
      return;
    }
    final isNotBasic = state.swType != SWType.basic;

    if (isNotBasic && !state.appSmartWidget.isValid()) {
      BotToastUtils.showError(gc.t.useValidAppUrl);
      return;
    }

    final image = state.smartWidgetBox.image;

    if (!isNotBasic && image.url.trim().isEmpty) {
      BotToastUtils.showError(gc.t.selectValidUrlImage);
      return;
    }

    final input = state.smartWidgetBox.inputField;
    final buttons = state.smartWidgetBox.buttons;

    if (!isNotBasic) {
      if (buttons.isEmpty) {
        BotToastUtils.showError(gc.t.buttonRequired);
        return;
      }

      for (final button in buttons) {
        if (button.url.isEmpty) {
          BotToastUtils.showError(gc.t.buttonNoUrl);
          return;
        }
      }
    }

    final cancel = BotToast.showLoading();

    try {
      final event = await Event.genEvent(
        content: state.title,
        kind: EventKind.SMART_WIDGET_ENH,
        signer: signer,
        tags: [
          getClientTag(),
          [
            'd',
            if (sm != null && isCloning != null && !isCloning!)
              sm!.identifier
            else
              randomHexString(16)
          ],
          ['image', if (isNotBasic) state.appSmartWidget.image else image.url],
          ['icon', if (isNotBasic) state.appSmartWidget.icon else state.icon],
          if (!isNotBasic && input != null) ...[
            ['input', input.placeholder]
          ],
          if (isNotBasic) ...[
            [
              'button',
              state.appSmartWidget.buttonTitle,
              'app',
              state.appSmartWidget.url
            ]
          ] else if (buttons.isNotEmpty) ...[
            ...buttons.map(
              (e) => ['button', e.text, e.type.name.toLowerCase(), e.url],
            )
          ],
          ['l', state.swType.name.toLowerCase()],
          if (isNotBasic)
            if (state.appSmartWidget.keywords.isNotEmpty)
              ...state.appSmartWidget.keywords.map(
                (e) => ['t', e],
              ),
          if (!isNotBasic)
            if (state.keywords.isNotEmpty)
              ...state.keywords.map(
                (e) => ['t', e],
              ),
        ],
      );

      if (event == null) {
        cancel.call();
        return;
      }

      cancel.call();

      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        relays: currentUserRelayList.writes,
        setProgress: true,
      );

      if (isSuccessful) {
        onSuccess.call(SmartWidget.fromEvent(event));
        nostrRepository.deleteSmartWidgetDraft(id: swAutoSaveModel.id);
        BotToastUtils.showSuccess(
          t.smartWidgetPublishedSuccessfuly.capitalizeFirst(),
        );
      } else {
        BotToastUtils.showUnreachableRelaysError();
      }

      cancel.call();
    } catch (e) {
      cancel.call();
      BotToastUtils.showError(
        t.errorAddingWidget.capitalizeFirst(),
      );
    }
  }
}
