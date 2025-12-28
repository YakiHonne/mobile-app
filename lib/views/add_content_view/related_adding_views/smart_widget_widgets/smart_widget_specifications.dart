// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../common/animations/heartbeat_fade.dart';
import '../../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../../logic/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/custom_drop_down.dart';
import '../../../widgets/dotted_container.dart';
import 'smart_widget_app_specification.dart';
import 'smart_widget_component_customization.dart';
import 'smart_widget_drafts.dart';
import 'smart_widget_pulldown_button.dart';
import 'smart_widgets_templates_view.dart';

class FrameSpecifications extends HookWidget {
  const FrameSpecifications({
    super.key,
    required this.toggleView,
  });

  final bool toggleView;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    void browseTemplates() {
      showModalBottomSheet(
        context: context,
        builder: (_) {
          return BlocProvider.value(
            value: context.read<WriteSmartWidgetCubit>(),
            child: SmartWidgetTemplatesView(
              onSmartWidgetSelected: (box) {
                context
                    .read<WriteSmartWidgetCubit>()
                    .setSmartWidgetContainer(box);
                context.read<WriteSmartWidgetCubit>().setOnboardingOff();
              },
            ),
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    void drafts() {
      showModalBottomSheet(
        context: context,
        builder: (_) {
          return BlocProvider.value(
            value: context.read<WriteSmartWidgetCubit>(),
            child: SmartWidgetsDrafts(
              onSmartWidgetDraftSelected: (swSaveModel) {
                context
                    .read<WriteSmartWidgetCubit>()
                    .setSwAutoSaveModel(swSaveModel);
                context.read<WriteSmartWidgetCubit>().setOnboardingOff();
              },
              onSmartWidgetPublished: (swSaveModel) {
                context
                    .read<WriteSmartWidgetCubit>()
                    .setSwAutoSaveModel(swSaveModel);
                context.read<WriteSmartWidgetCubit>().setFramePublishStep(
                      SmartWidgetPublishSteps.content,
                    );
              },
            ),
          );
        },
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      );
    }

    return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      builder: (context, state) {
        if (state.isOnboarding) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: kDefaultPadding / 2,
              horizontal: isTablet ? 10.w : kDefaultPadding / 2,
            ),
            child: ListView(
              children: [
                Lottie.asset(
                  LottieAnimations.widgets,
                  height: 25.h,
                  fit: BoxFit.contain,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  context.t.smartWidgetBuilder.capitalizeFirst(),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                Text(
                  context.t.startBuildingSmartWidget.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                _draftsRow(context, drafts, browseTemplates)
              ],
            ),
          );
        }

        final box = state.smartWidgetBox;

        return ListView(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          children: [
            CustomDropDown(
              list: SWType.values
                  .map(
                    (e) => e.name.capitalizeFirst(),
                  )
                  .toList(),
              defaultValue: state.swType.name.capitalizeFirst(),
              onChanged: (type) {
                final t = SWType.values.firstWhere(
                  (e) => e.name.capitalizeFirst() == type!.capitalizeFirst(),
                  orElse: () => SWType.basic,
                );

                if (t == SWType.basic) {
                  context.read<WriteSmartWidgetCubit>().setType(t);
                } else {
                  context.read<WriteSmartWidgetCubit>().setType(t);
                }
              },
            ),
            if (state.swType != SWType.basic) ...[
              const SmartWidgetAppSpecificationRow(),
            ],
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            if (!toggleView) ...[
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SmallRectangularButton(
                    onClick: drafts,
                    turns: 0,
                    icon: FeatureIcons.swDraft,
                    backgroundColor: null,
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  SmallRectangularButton(
                    onClick: browseTemplates,
                    icon: FeatureIcons.templates,
                    turns: 0,
                    backgroundColor: null,
                  ),
                ],
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
            ],
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            if (state.swType == SWType.basic)
              SMEditableContainer(
                smartWidgetBox: box,
                toggleView: toggleView,
              )
            else
              SWappSmartWidget(
                toggleView: toggleView,
              ),
          ],
        );
      },
    );
  }

  Row _draftsRow(
      BuildContext context, Function() drafts, Function() browseTemplates) {
    return Row(
      children: [
        Expanded(
          child: OnboardingOption(
            icon: FeatureIcons.add,
            onClick: () {
              context
                  .read<AddContentCubit>()
                  .setBottomNavigationBarState(false);

              context.read<WriteSmartWidgetCubit>().setOnboardingOff();
            },
            title: context.t.blankWidget.capitalizeFirst(),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: OnboardingOption(
            icon: FeatureIcons.swDraft,
            onClick: () {
              context
                  .read<AddContentCubit>()
                  .setBottomNavigationBarState(false);
              drafts();
            },
            title: context.t.myDrafts.capitalizeFirst(),
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
        Expanded(
          child: OnboardingOption(
            icon: FeatureIcons.templates,
            onClick: () {
              context
                  .read<AddContentCubit>()
                  .setBottomNavigationBarState(false);

              browseTemplates();
            },
            title: context.t.templates.capitalizeFirst(),
          ),
        ),
      ],
    );
  }
}

class SWappSmartWidget extends StatelessWidget {
  const SWappSmartWidget({super.key, required this.toggleView});

  final bool toggleView;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            if (!toggleView) {
              showModalBottomSheet(
                context: context,
                builder: (_) {
                  return BlocProvider.value(
                    value: context.read<WriteSmartWidgetCubit>(),
                    child: const SmartWidgetAppSpecification(),
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            } else if (state.appSmartWidget.isValid()) {}
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: Theme.of(context).cardColor,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                _appSmartWidget(state, width, context),
                if (state.appSmartWidget.isValid()) ...[
                  Padding(
                    padding: const EdgeInsets.all(kDefaultPadding / 1.5),
                    child: Text(
                      state.appSmartWidget.buttonTitle,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  AnimatedSwitcher _appSmartWidget(
      WriteSmartWidgetState state, double width, BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: state.appSmartWidget.isValid()
          ? CommonThumbnail(
              key: const ValueKey('image'),
              image: state.appSmartWidget.image,
              radius: kDefaultPadding / 2,
              isRound: true,
              width: width,
              height: state.appSmartWidget.image.isEmpty ? (width * 8) / 16 : 0,
            )
          : AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Center(
                  child: HeartbeatFade(
                    child: SvgPicture.asset(
                      FeatureIcons.smartWidget,
                      width: 40,
                      height: 40,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColorDark,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class SMEditableContainer extends StatelessWidget {
  const SMEditableContainer({
    super.key,
    required this.smartWidgetBox,
    required this.toggleView,
  });

  final SmartWidgetBox smartWidgetBox;
  final bool toggleView;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            spacing: kDefaultPadding / 2,
            children: [
              if (!toggleView) const SizedBox.shrink(),
              ImageEditableContainer(
                smartWidgetBox: smartWidgetBox,
                toggleView: toggleView,
              ),
              if ((toggleView &&
                      (smartWidgetBox.inputField != null ||
                          smartWidgetBox.buttons.isNotEmpty)) ||
                  !toggleView)
                _actionsColumn(),
            ],
          ),
        );
      },
    );
  }

  Padding _actionsColumn() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: Column(
        spacing: kDefaultPadding / 2,
        children: [
          if ((toggleView && smartWidgetBox.inputField != null) || !toggleView)
            InputFieldEditableContainer(
              smartWidgetBox: smartWidgetBox,
              toggleView: toggleView,
            ),
          if ((toggleView && smartWidgetBox.buttons.isNotEmpty) || !toggleView)
            ButtonsEditableContainer(
              smartWidgetBox: smartWidgetBox,
              toggleView: toggleView,
            ),
          if (smartWidgetBox.inputField != null ||
              smartWidgetBox.buttons.isNotEmpty)
            const SizedBox.shrink()
        ],
      ),
    );
  }
}

class ImageEditableContainer extends StatelessWidget {
  const ImageEditableContainer({
    super.key,
    required this.smartWidgetBox,
    required this.toggleView,
  });

  final SmartWidgetBox smartWidgetBox;
  final bool toggleView;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final url = smartWidgetBox.image.url;
        final width = MediaQuery.of(context).size.width;

        final child = GestureDetector(
          onTap: () {
            if (!toggleView) {
              showModalBottomSheet(
                context: context,
                builder: (_) {
                  return BlocProvider.value(
                    value: context.read<WriteSmartWidgetCubit>(),
                    child: FrameComponentCustomization(
                      boxComponent: smartWidgetBox.image,
                    ),
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: smartWidgetBox.image.url.isEmpty
                ? _selectImage(context)
                : _commonThumbnail(width, url),
          ),
        );

        return !toggleView
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: DottedBorder(
                  color: Theme.of(context).dividerColor,
                  borderType: BorderType.rRect,
                  radius: const Radius.circular(kDefaultPadding / 2),
                  child: child,
                ),
              )
            : child;
      },
    );
  }

  CommonThumbnail _commonThumbnail(double width, String url) {
    return CommonThumbnail(
      key: const ValueKey('image'),
      image: smartWidgetBox.image.url,
      radius: kDefaultPadding / 2,
      isRound: true,
      width: width,
      height: url.isEmpty ? (width * 8) / 16 : 0,
    );
  }

  AspectRatio _selectImage(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 8,
      child: Container(
        key: const ValueKey('container'),
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          color: Theme.of(context).cardColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                FeatureIcons.image,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                context.t.selectImage,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InputFieldEditableContainer extends StatelessWidget {
  const InputFieldEditableContainer({
    super.key,
    required this.smartWidgetBox,
    required this.toggleView,
  });

  final SmartWidgetBox smartWidgetBox;
  final bool toggleView;

  @override
  Widget build(BuildContext context) {
    final isInputAvailable = smartWidgetBox.inputField != null;
    final input = smartWidgetBox.inputField;

    return toggleView
        ? isInputAvailable
            ? AbsorbPointer(
                child: TextField(
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: input!.placeholder,
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        kDefaultPadding / 1.5,
                      ),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink()
        : _dottedContainer(context, isInputAvailable, input);
  }

  SizedBox _dottedContainer(BuildContext context, bool isInputAvailable,
      SmartWidgetInputField? input) {
    return SizedBox(
      child: DottedBorder(
        color: Theme.of(context).dividerColor,
        borderType: BorderType.rRect,
        radius: const Radius.circular(kDefaultPadding / 2),
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 4),
          child: Column(
            spacing: kDefaultPadding / 4,
            children: [
              if (isInputAvailable) _inputField(context, input),
              if (!isInputAvailable)
                _addInputField(context)
              else
                _deleteRow(context, isInputAvailable),
            ],
          ),
        ),
      ),
    );
  }

  Row _deleteRow(BuildContext context, bool isInputAvailable) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: GridSideButton(
            isHorizontal: true,
            icon: FeatureIcons.editArticle,
            backGroundColor: Theme.of(context).cardColor,
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (_) {
                  return BlocProvider.value(
                    value: context.read<WriteSmartWidgetCubit>(),
                    child: FrameComponentCustomization(
                      boxComponent: smartWidgetBox.inputField!,
                    ),
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            },
            isSmall: true,
          ),
        ),
        Expanded(
          child: GridSideButton(
            isHorizontal: true,
            icon: FeatureIcons.trash,
            backGroundColor:
                isInputAvailable ? kRed : Theme.of(context).cardColor,
            onTap: () {
              context.read<WriteSmartWidgetCubit>().deleteInputField();
            },
            isSmall: true,
          ),
        ),
      ],
    );
  }

  SizedBox _addInputField(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: Theme.of(context).cardColor,
        ),
        onPressed: () => context.read<WriteSmartWidgetCubit>().addInputField(),
        label: Text(
          context.t.addInputField,
        ),
        icon: SvgPicture.asset(
          FeatureIcons.addRaw,
          width: 15,
          height: 15,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColorDark,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Center _inputField(BuildContext context, SmartWidgetInputField? input) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          key: const ValueKey('inputField'),
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (_) {
                return BlocProvider.value(
                  value: context.read<WriteSmartWidgetCubit>(),
                  child: FrameComponentCustomization(
                    boxComponent: smartWidgetBox.inputField!,
                  ),
                );
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            );
          },
          child: AbsorbPointer(
            child: TextField(
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: input!.placeholder,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding / 1.5,
                  ),
                  borderSide: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ButtonsEditableContainer extends HookWidget {
  const ButtonsEditableContainer({
    super.key,
    required this.smartWidgetBox,
    required this.toggleView,
  });

  final SmartWidgetBox smartWidgetBox;
  final bool toggleView;

  @override
  Widget build(BuildContext context) {
    final isButtonsAvailable = smartWidgetBox.buttons.isNotEmpty;
    final buttons = smartWidgetBox.buttons;
    final selectedButton = useState<SmartWidgetButton?>(null);

    return toggleView
        ? isButtonsAvailable
            ? ButtonsGrid(
                buttons: buttons
                    .map(
                      (e) => SMEditableTextButton(
                        text: e.text,
                        onSelected: () {},
                        isSelected: false,
                        smartWidgetButton: e,
                        index: 0,
                      ),
                    )
                    .toList(),
              )
            : const SizedBox.shrink()
        : _actionButtons(context, isButtonsAvailable, buttons, selectedButton);
  }

  DottedBorder _actionButtons(
      BuildContext context,
      bool isButtonsAvailable,
      List<SmartWidgetButton> buttons,
      ValueNotifier<SmartWidgetButton?> selectedButton) {
    return DottedBorder(
      color: Theme.of(context).dividerColor,
      borderType: BorderType.rRect,
      radius: const Radius.circular(kDefaultPadding / 2),
      child: Column(
        children: [
          _editableTextButton(
              isButtonsAvailable, buttons, selectedButton, context),
          if (!toggleView && (buttons.length < 6)) ...[
            _addButton(context),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
        ],
      ),
    );
  }

  Padding _addButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 4,
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.comfortable,
            backgroundColor: Theme.of(context).cardColor,
          ),
          onPressed: () => context.read<WriteSmartWidgetCubit>().addButton(),
          label: Text(
            context.t.addButton,
          ),
          icon: SvgPicture.asset(
            FeatureIcons.addRaw,
            width: 15,
            height: 15,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  Center _editableTextButton(
      bool isButtonsAvailable,
      List<SmartWidgetButton> buttons,
      ValueNotifier<SmartWidgetButton?> selectedButton,
      BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isButtonsAvailable
              ? ButtonsGrid(
                  buttons: buttons
                      .map(
                        (e) => SMEditableTextButton(
                          text: e.text,
                          isSelected: identical(selectedButton.value, e),
                          onSelected: () {
                            if (identical(selectedButton.value, e)) {
                              selectedButton.value = null;
                            } else {
                              selectedButton.value = null;
                              selectedButton.value = e;
                            }
                          },
                          smartWidgetButton: e,
                          index: buttons.indexOf(e),
                        ),
                      )
                      .toList(),
                )
              : Container(
                  height: 40,
                  key: const ValueKey('container'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    context.t.addButton,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                  ),
                ),
        ),
      ),
    );
  }
}

class ButtonsGrid extends StatelessWidget {
  final List<Widget> buttons;

  const ButtonsGrid({super.key, required this.buttons})
      : assert(buttons.length <= 6, 'Button list cannot exceed 6 items.');

  @override
  Widget build(BuildContext context) {
    final int total = buttons.length;
    final int firstRowCount = total > 3 ? 3 : total;
    final int secondRowCount = total > 3 ? total - 3 : 0;

    Widget buildRow(List<Widget> rowItems) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kDefaultPadding / 4,
        children: rowItems.map((b) => Expanded(child: b)).toList(),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: kDefaultPadding / 4,
      children: [
        buildRow(buttons.sublist(0, firstRowCount)),
        if (secondRowCount > 0) buildRow(buttons.sublist(3, total)),
      ],
    );
  }
}

class SMEditableTextButton extends StatelessWidget {
  const SMEditableTextButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onSelected,
    required this.index,
    required this.smartWidgetButton,
  });

  final String text;
  final bool isSelected;
  final int index;
  final SmartWidgetButton smartWidgetButton;
  final Function() onSelected;

  @override
  Widget build(BuildContext context) {
    final widget = TextButton(
      onPressed: onSelected,
      style: TextButton.styleFrom(
        visualDensity: const VisualDensity(horizontal: -0.5, vertical: -0.5),
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: Theme.of(context).primaryColorDark,
            ),
      ),
    );

    if (isSelected) {
      return Stack(
        children: [
          DottedBorder(
            color: Theme.of(context).primaryColor,
            borderType: BorderType.rRect,
            radius: const Radius.circular(kDefaultPadding / 2),
            padding: const EdgeInsets.all(kDefaultPadding / 6),
            child: SizedBox(
              width: double.infinity,
              child: widget,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Padding(
              padding: const EdgeInsets.all(kDefaultPadding / 6),
              child: SmartWidgetButtonPulldownButton(
                smartWidgetButton: smartWidgetButton,
              ),
            ),
          )
        ],
      );
    } else {
      return widget;
    }
  }
}

class OnboardingOption extends StatelessWidget {
  const OnboardingOption({
    super.key,
    required this.onClick,
    required this.title,
    required this.icon,
  });

  final Function() onClick;
  final String title;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        onTap: onClick,
        child: Container(
          height: constraints.maxWidth,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kDefaultPadding / 2),
            color: Theme.of(context).cardColor,
            border: Border.all(
              color: kDimGrey.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                icon,
                width: 30,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridSideButton extends StatelessWidget {
  const GridSideButton({
    super.key,
    required this.icon,
    required this.backGroundColor,
    required this.onTap,
    required this.isSmall,
    this.isHorizontal,
  });

  final String icon;
  final Color backGroundColor;
  final Function() onTap;
  final bool isSmall;
  final bool? isHorizontal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isHorizontal != null ? double.infinity : kDefaultPadding * 1.2,
        height: isHorizontal != null ? kDefaultPadding * 1.3 : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 4),
          color: backGroundColor,
        ),
        child: Center(
          child: SvgPicture.asset(
            icon,
            width: 15,
            height: 15,
            colorFilter: const ColorFilter.mode(
              kWhite,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
