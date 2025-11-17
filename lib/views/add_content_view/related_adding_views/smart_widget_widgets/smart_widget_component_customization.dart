// ignore_for_file: public_member_api_docs, sort_constructors_first, no_self_assignments

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../../../common/common_regex.dart';
import '../../../../logic/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import '../../../wallet_view/widgets/user_to_zap_view.dart';
import '../../../widgets/custom_date_picker.dart';
import '../../../widgets/custom_drop_down.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/data_providers.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/profile_picture.dart';
import '../article_widgets/article_image_selector.dart';

class FrameComponentCustomization extends HookWidget {
  const FrameComponentCustomization({
    super.key,
    required this.boxComponent,
    this.id,
  });

  final SmartWidgetBoxComponent boxComponent;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final c = useState(boxComponent);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.70,
          minChildSize: 0.40,
          maxChildSize: 0.70,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const ModalBottomSheetHandle(),
                Expanded(
                  child: getSmartWidgetComponentWidget(
                    boxComponent,
                    scrollController,
                    (component) {
                      c.value = component;
                    },
                  ),
                ),
                _actionButtons(context, c),
              ],
            );
          },
        ),
      ),
    );
  }

  SafeArea _actionButtons(
      BuildContext context, ValueNotifier<SmartWidgetBoxComponent> c) {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    side: const BorderSide(color: kRed),
                  ),
                  child: Text(
                    context.t.cancel.capitalizeFirst(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: kRed,
                        ),
                  ),
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 4,
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    final component = c.value;

                    final cp = isValidSmartWidgetComponent(component, context);

                    if (!cp) {
                      return;
                    }

                    if (c.value is SmartWidgetImage) {
                      context.read<WriteSmartWidgetCubit>().updateImageUrl(
                            (c.value as SmartWidgetImage).url,
                          );
                    } else if (c.value is SmartWidgetInputField) {
                      context
                          .read<WriteSmartWidgetCubit>()
                          .updateInputPlaceholder(
                            (c.value as SmartWidgetInputField).placeholder,
                          );
                    } else if (id != null) {
                      context.read<WriteSmartWidgetCubit>().updateButton(
                            id!,
                            c.value as SmartWidgetButton,
                          );
                    }

                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                  child: Text(
                    context.t.update.capitalizeFirst(),
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).primaryColorDark,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool isValidSmartWidgetComponent(
    SmartWidgetBoxComponent component,
    BuildContext context,
  ) {
    if (component is SmartWidgetButton) {
      final url = component.url;
      if (component.type == SWBType.Zap) {
        if (url.isNotEmpty &&
            (emailRegExp.hasMatch(url) ||
                url.toLowerCase().startsWith('lnbc') ||
                url.toLowerCase().startsWith('lnurl'))) {
          return true;
        } else {
          BotToastUtils.showError(
            context.t.invalidInvoiceLnurl.capitalizeFirst(),
          );

          return false;
        }
      }

      if (component.type == SWBType.Post) {
        final matches = urlRegExp.allMatches(url);

        if (matches.isEmpty) {
          BotToastUtils.showError(
            context.t.addValidUrl.capitalizeFirst(),
          );

          return false;
        } else {
          return ButtonFunctions.fromUrl(url).checkValidity(context);
        }
      } else {
        final reg =
            component.type == SWBType.Nostr ? Nip19.nip19regex : urlRegExp;

        final matches = reg.allMatches(url);

        if (matches.isEmpty) {
          BotToastUtils.showError(
            context.t.addValidUrl.capitalizeFirst(),
          );

          return false;
        } else {
          return true;
        }
      }
    }

    return true;
  }

  Widget getSmartWidgetComponentWidget(
    SmartWidgetBoxComponent component,
    ScrollController controller,
    Function(SmartWidgetBoxComponent) updateFrame,
  ) {
    if (component is SmartWidgetImage) {
      return SmartWidgetImageCustomization(
        image: component,
        controller: controller,
        updateImage: updateFrame,
      );
    } else if (component is SmartWidgetButton) {
      return SmartWidgetButtonCustomization(
        button: component,
        controller: controller,
        updateButton: updateFrame,
      );
    } else if (component is SmartWidgetInputField) {
      return SmartWidgetInputCustomization(
        input: component,
        controller: controller,
        updateInput: updateFrame,
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class SmartWidgetInputCustomization extends HookWidget {
  const SmartWidgetInputCustomization({
    super.key,
    required this.input,
    required this.controller,
    required this.updateInput,
  });

  final SmartWidgetInputField input;
  final ScrollController controller;
  final Function(SmartWidgetInputField) updateInput;

  @override
  Widget build(BuildContext context) {
    final placeholder = useState(input.placeholder);
    final placeholderController =
        useTextEditingController(text: input.placeholder);

    final t = useCallback(
      () {
        updateInput.call(
          input.copyWith(
            placeHolder: placeholder.value,
          ),
        );
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          context.t.inputFieldCustomization.capitalizeFirst(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        TextFormField(
          controller: placeholderController,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (value) {
            placeholder.value = value;
            t.call();
          },
          decoration: InputDecoration(
            hintText: context.t.placeholder.capitalizeFirst(),
          ),
        ),
      ],
    );
  }
}

class SmartWidgetImageCustomization extends HookWidget {
  const SmartWidgetImageCustomization({
    super.key,
    required this.image,
    required this.controller,
    required this.updateImage,
  });

  final SmartWidgetImage image;
  final ScrollController controller;
  final Function(SmartWidgetImage) updateImage;

  @override
  Widget build(BuildContext context) {
    final url = useState(image.url);
    final urlController = useTextEditingController(text: image.url);

    final t = useCallback(
      () {
        updateImage.call(image.copyWith(url: url.value));
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          context.t.imageCustomization.capitalizeFirst(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: urlController,
                onChanged: (value) {
                  url.value = value;
                  t.call();
                },
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: context.t.imageUrl.capitalizeFirst(),
                ),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return ImageSelector(
                      onTap: (link) {
                        url.value = link;
                        urlController.text = link;
                        t.call();
                      },
                    );
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: FeatureIcons.upload,
              vd: 2,
              size: 25,
              backgroundColor: Theme.of(context).cardColor,
            ),
          ],
        ),
      ],
    );
  }
}

class SmartWidgetButtonCustomization extends HookWidget {
  const SmartWidgetButtonCustomization({
    super.key,
    required this.button,
    required this.controller,
    required this.updateButton,
  });

  final SmartWidgetButton button;
  final ScrollController controller;
  final Function(SmartWidgetButton) updateButton;

  @override
  Widget build(BuildContext context) {
    final text = useState(button.text);
    final type = useState(button.type);
    final url = useState(button.url);
    final inputFieldController = useTextEditingController(text: url.value);

    final refreshData = useCallback(
      () {
        updateButton.call(
          button.copyWith(
            text: text.value,
            type: type.value,
            url: url.value,
          ),
        );
      },
    );

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      children: [
        Text(
          context.t.buttonCustomization,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        TextFormField(
          initialValue: text.value,
          style: Theme.of(context).textTheme.bodyMedium,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (value) {
            text.value = value;
            refreshData.call();
          },
          decoration: InputDecoration(
            labelText: context.t.buttonText,
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        CustomDropDown(
          list: SWBType.values
              .where(
                (element) => element != SWBType.App,
              )
              .map((e) => e.name)
              .toList(),
          defaultValue: type.value.name,
          onChanged: (val) {
            type.value = SWBType.values.firstWhere(
              (element) => element.name == val,
              orElse: () => SWBType.Redirect,
            );

            inputFieldController.clear();

            url.value = '';
            refreshData.call();
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        getCurrentButtonCustomization(
          type: type,
          url: url,
          inputFieldController: inputFieldController,
          refreshData: refreshData,
        ),
      ],
    );
  }

  Widget getCurrentButtonCustomization({
    required ValueNotifier<SWBType> type,
    required ValueNotifier<String> url,
    required TextEditingController inputFieldController,
    required Function() refreshData,
  }) {
    switch (type.value) {
      case SWBType.Redirect:
        return RegulatInputfield(
          type: type,
          url: url,
          inputFieldController: inputFieldController,
          refreshData: refreshData,
        );
      case SWBType.Nostr:
        return RegulatInputfield(
          type: type,
          url: url,
          inputFieldController: inputFieldController,
          refreshData: refreshData,
        );
      case SWBType.App:
        return RegulatInputfield(
          type: type,
          url: url,
          inputFieldController: inputFieldController,
          refreshData: refreshData,
        );
      case SWBType.Zap:
        return ButtonZapCustomization(
          url: url,
          inputFieldController: inputFieldController,
          refreshData: refreshData,
        );
      case SWBType.Post:
        return ButtonPostCustomization(
          url: url,
          inputFieldController: inputFieldController,
          refreshData: refreshData,
        );
    }
  }
}

class ButtonPostCustomization extends HookWidget {
  const ButtonPostCustomization({
    super.key,
    required this.url,
    required this.inputFieldController,
    required this.refreshData,
  });

  final ValueNotifier<String> url;
  final TextEditingController inputFieldController;
  final Function() refreshData;

  @override
  Widget build(BuildContext context) {
    final list = postFunctionsMap.keys.toList();
    final buttonFunctions = useState(
      ButtonFunctions.fromUrl(url.value),
    );

    void refresh() {
      url.value = buttonFunctions.value.currentUrl();
      refreshData.call();
    }

    return Builder(
      builder: (context) {
        final currentType = buttonFunctions.value.type;

        return Column(
          spacing: kDefaultPadding / 4,
          children: [
            CustomDropDown(
              list: list,
              defaultValue: currentType,
              onChanged: (type) {
                final baseUrl = postFunctionsMap[type]!;

                buttonFunctions.value = ButtonFunctions(
                  type: type!,
                  baseUrl: baseUrl,
                  startsAt: baseUrl == postUrls[10] ? DateTime.now() : null,
                );

                refresh();
              },
            ),
            if (buttonFunctions.value.type == postFunctionsMap.keys.first) ...[
              TextFormField(
                initialValue: url.value,
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) {
                  url.value = value;
                  refreshData.call();
                },
                decoration: InputDecoration(
                  labelText: context.t.url,
                ),
              ),
            ] else ...[
              if (buttonFunctions.value.requiresParams())
                _lud16Column(
                  buttonFunctions,
                  () => refresh(),
                ),
              if (buttonFunctions.value.requiredInput() &&
                  context
                          .read<WriteSmartWidgetCubit>()
                          .state
                          .smartWidgetBox
                          .inputField ==
                      null) ...[
                Text(
                  context.t.missingInputDesc,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: kRed,
                      ),
                )
              ]
            ],
          ],
        );
      },
    );
  }

  Builder _lud16Column(
      ValueNotifier<ButtonFunctions> buttonFunctions, Function() refresh) {
    return Builder(
      builder: (context) {
        final hasTime = buttonFunctions.value.shouldHaveTime();
        final hasEndAt = buttonFunctions.value.shouldHaveEndsAt();
        final hasEndLud16 = buttonFunctions.value.shouldHaveLud16();
        final hasPubkeys = buttonFunctions.value.shouldHavePubkeys();

        return Column(
          children: [
            if (hasEndLud16)
              TextFormField(
                initialValue: buttonFunctions.value.lud16,
                style: Theme.of(context).textTheme.bodyMedium,
                onChanged: (value) {
                  buttonFunctions.value = buttonFunctions.value.copyWith()
                    ..lud16 = value;
                  refresh();
                },
                decoration: InputDecoration(
                  labelText: context.t.lightningAddress,
                ),
              ),
            if (hasTime || hasEndAt)
              Builder(
                builder: (context) {
                  final selectedDate = hasTime
                      ? buttonFunctions.value.time
                      : buttonFunctions.value.endsAt;

                  return SwDatePicker(
                    selectedDate: selectedDate,
                    hasTime: hasTime,
                    buttonFunctions: buttonFunctions,
                    refresh: refresh,
                  );
                },
              ),
            if (hasPubkeys)
              SwProfilePicker(
                buttonFunctions: buttonFunctions,
                refresh: refresh,
              ),
          ],
        );
      },
    );
  }
}

class SwProfilePicker extends HookWidget {
  const SwProfilePicker({
    super.key,
    required this.buttonFunctions,
    required this.refresh,
  });
  final ValueNotifier<ButtonFunctions> buttonFunctions;
  final Function() refresh;

  @override
  Widget build(BuildContext context) {
    final searchAuthorFunc = useCallback(
      () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return UserToZap(
              onUserSelected: (user) {
                buttonFunctions.value = buttonFunctions.value.addProfile(
                  Nip19.encodePubkey(user.pubkey),
                );

                refresh();

                YNavigator.pop(context);
              },
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
    );

    return Column(
      spacing: kDefaultPadding / 4,
      children: [
        _searchContainer(searchAuthorFunc, context),
        Builder(
          builder: (context) {
            final pubkeys = buttonFunctions.value.pubkeys?.toList();

            if (pubkeys != null) {
              return _metadataList(pubkeys);
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  SizedBox _metadataList(List<String> pubkeys) {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(
          width: kDefaultPadding / 4,
        ),
        itemBuilder: (context, index) {
          return MetadataProvider(
            pubkey: pubkeys[index],
            child: (metadata, nip05) {
              return Container(
                width: 65.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
                  color: Theme.of(context).cardColor,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 0.5,
                  ),
                ),
                padding: const EdgeInsets.all(kDefaultPadding / 4),
                child: Row(
                  spacing: kDefaultPadding / 4,
                  children: [
                    ProfilePicture3(
                      size: 40,
                      image: metadata.picture,
                      pubkey: metadata.pubkey,
                      padding: 0,
                      strokeWidth: 0,
                      strokeColor: kTransparent,
                      onClicked: () {},
                    ),
                    Expanded(
                      child: Text(
                        metadata.getName(),
                      ),
                    ),
                    CustomIconButton(
                      onClicked: () {
                        buttonFunctions.value =
                            buttonFunctions.value.removeProfile(
                          Nip19.encodePubkey(metadata.pubkey),
                        );

                        refresh();
                      },
                      icon: FeatureIcons.closeRaw,
                      size: 20,
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  ],
                ),
              );
            },
          );
        },
        itemCount: pubkeys.length,
      ),
    );
  }

  GestureDetector _searchContainer(
      Function() searchAuthorFunc, BuildContext context) {
    return GestureDetector(
      onTap: searchAuthorFunc,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: Row(
          children: [
            const SizedBox(
              width: kDefaultPadding / 1.6,
            ),
            Expanded(
              child: Text(
                context.t.searchNameNpub,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            CustomIconButton(
              onClicked: searchAuthorFunc,
              icon: FeatureIcons.user,
              size: 20,
              backgroundColor: Theme.of(context).cardColor,
            ),
          ],
        ),
      ),
    );
  }
}

class SwDatePicker extends StatelessWidget {
  const SwDatePicker({
    super.key,
    required this.selectedDate,
    required this.hasTime,
    required this.buttonFunctions,
    required this.refresh,
  });

  final DateTime? selectedDate;
  final bool hasTime;
  final ValueNotifier<ButtonFunctions> buttonFunctions;
  final Function() refresh;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.only(
            left: kDefaultPadding,
            right: kDefaultPadding / 4,
          ),
          margin: const EdgeInsets.only(top: kDefaultPadding / 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedDate != null
                      ? dateFormat4.format(selectedDate!)
                      : '--- --, ---- --:--',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              _calendarButton(context)
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: kDefaultPadding,
          child: Text(
            hasTime ? context.t.countdown : context.t.contentEndsAt,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ),
      ],
    );
  }

  IconButton _calendarButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (selectedDate == null) {
          showDialog(
            context: context,
            builder: (_) {
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                ),
                child: PickDateTimeWidget(
                  focusedDate: selectedDate ?? DateTime.now(),
                  isAfter: true,
                  onDateSelected: (selectedDate) {
                    if (hasTime) {
                      buttonFunctions.value = buttonFunctions.value.copyWith()
                        ..time = selectedDate;
                    } else {
                      buttonFunctions.value = buttonFunctions.value.copyWith()
                        ..endsAt = selectedDate;
                    }

                    refresh();
                  },
                  onClearDate: () {
                    if (hasTime) {
                      buttonFunctions.value = buttonFunctions.value.copyWith()
                        ..time = null;
                    } else {
                      buttonFunctions.value = buttonFunctions.value.copyWith()
                        ..endsAt = null;
                    }

                    refresh();
                  },
                ),
              );
            },
          );
        } else {
          if (hasTime) {
            buttonFunctions.value = buttonFunctions.value.copyWith()
              ..time = null;
          } else {
            buttonFunctions.value = buttonFunctions.value.copyWith()
              ..endsAt = null;
          }

          refresh();
        }
      },
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).cardColor,
      ),
      icon: SvgPicture.asset(
        selectedDate == null ? FeatureIcons.calendar : FeatureIcons.closeRaw,
        width: 22,
        height: 22,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class RegulatInputfield extends StatelessWidget {
  const RegulatInputfield({
    super.key,
    required this.type,
    required this.url,
    required this.inputFieldController,
    required this.refreshData,
  });

  final ValueNotifier<SWBType> type;
  final ValueNotifier<String> url;
  final TextEditingController inputFieldController;
  final Function() refreshData;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: url.value,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (value) {
        url.value = value;
        refreshData.call();
      },
      decoration: InputDecoration(
        labelText: hintText(type.value, context),
      ),
    );
  }

  String hintText(SWBType action, BuildContext context) {
    String hintText = '';

    switch (action) {
      case SWBType.Redirect:
        hintText = context.t.url;
      case SWBType.Nostr:
        hintText = context.t.nostrScheme;
      case SWBType.Zap:
        hintText = context.t.invoiceOrLN;
      case SWBType.Post:
        hintText = context.t.url;
      case SWBType.App:
        hintText = context.t.url;
    }

    return hintText;
  }
}

class ButtonZapCustomization extends HookWidget {
  const ButtonZapCustomization({
    super.key,
    required this.url,
    required this.inputFieldController,
    required this.refreshData,
  });

  final ValueNotifier<String> url;
  final TextEditingController inputFieldController;
  final Function() refreshData;

  @override
  Widget build(BuildContext context) {
    final toggleSatsMode = useState(url.value.startsWith('lnbc'));
    final userToZap = useState<Metadata?>(null);

    final searchAuthorFunc = useCallback(
      () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return UserToZap(
              onUserSelected: (user) {
                userToZap.value = user;

                final String la =
                    (user.lud16.isNotEmpty ? user.lud16 : user.lud06)
                        .toLowerCase();

                if (la.contains('@') || la.startsWith('lnurl')) {
                  inputFieldController.text = la;
                  url.value = la;
                }

                refreshData.call();
                Navigator.pop(context);
              },
            );
          },
          isScrollControlled: true,
          useRootNavigator: true,
          useSafeArea: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        );
      },
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
            color: Theme.of(context).cardColor,
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 4),
          child: Row(
            children: [
              const SizedBox(
                width: kDefaultPadding / 1.6,
              ),
              Expanded(
                child: Text(
                  context.t.useInvoice,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: CupertinoSwitch(
                  value: toggleSatsMode.value,
                  activeTrackColor: Theme.of(context).primaryColor,
                  onChanged: (val) {
                    toggleSatsMode.value = val;
                    userToZap.value = null;
                    inputFieldController.clear();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        TextFormField(
          controller: inputFieldController,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (value) {
            url.value = value;
            refreshData.call();
          },
          decoration: InputDecoration(
            hintText: toggleSatsMode.value
                ? context.t.invoice
                : context.t.lightningAddress,
            hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        _searchFuncContainer(searchAuthorFunc, context, userToZap),
      ],
    );
  }

  GestureDetector _searchFuncContainer(Function() searchAuthorFunc,
      BuildContext context, ValueNotifier<Metadata?> userToZap) {
    return GestureDetector(
      onTap: searchAuthorFunc,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 1.2),
          color: Theme.of(context).cardColor,
        ),
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: userToZap.value != null
            ? Row(
                children: [
                  const SizedBox(
                    width: kDefaultPadding / 1.6,
                  ),
                  ProfilePicture2(
                    size: 25,
                    image: userToZap.value!.picture,
                    pubkey: userToZap.value!.pubkey,
                    padding: 0,
                    strokeWidth: 0,
                    reduceSize: true,
                    strokeColor: kTransparent,
                    onClicked: () {},
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 2,
                  ),
                  Expanded(
                    child: Text(
                      userToZap.value!.getName(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  CustomIconButton(
                    onClicked: () {
                      userToZap.value = null;
                      inputFieldController.clear();
                    },
                    icon: FeatureIcons.closeRaw,
                    size: 20,
                    backgroundColor: Theme.of(context).primaryColorLight,
                  ),
                ],
              )
            : Row(
                children: [
                  const SizedBox(
                    width: kDefaultPadding / 1.6,
                  ),
                  Expanded(
                    child: Text(
                      context.t.selectUserToZap,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  CustomIconButton(
                    onClicked: searchAuthorFunc,
                    icon: FeatureIcons.user,
                    size: 20,
                    backgroundColor: Theme.of(context).primaryColorLight,
                  ),
                ],
              ),
      ),
    );
  }
}

class DropDownRow extends StatelessWidget {
  const DropDownRow({
    super.key,
    required this.onChanged,
    required this.selectedOption,
    required this.title,
    required this.options,
  });

  final Function(String?) onChanged;
  final String selectedOption;
  final String title;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Flexible(
          child: CustomDropDown(
            list: options,
            defaultValue: selectedOption,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
