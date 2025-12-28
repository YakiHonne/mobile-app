// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../models/app_models/diverse_functions.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../utils/utils.dart';
import '../../add_content_view/related_adding_views/smart_widget_widgets/smart_widget_pulldown_button.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/empty_list.dart';
import 'smart_widget_container.dart';

class SmartWidgetChecker extends HookWidget {
  static const routeName = '/smartWidgetCheckerView';
  static Route route(RouteSettings settings) {
    final items = settings.arguments as List?;

    return CupertinoPageRoute(
      builder: (_) => SmartWidgetChecker(
        naddr: items?[0] as String?,
        swm: items?[1] as SmartWidget?,
        viewMode: items != null && items.length >= 3 ? items[2] : false,
      ),
    );
  }

  SmartWidgetChecker({
    super.key,
    this.naddr,
    this.swm,
    this.viewMode = false,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Smart widget checker view');
  }

  final String? naddr;
  final SmartWidget? swm;
  final bool viewMode;

  @override
  Widget build(BuildContext context) {
    final naddrTextEditingController =
        useTextEditingController(text: naddr ?? swm?.getScheme());
    final naddNotifier = useState<String>(naddr ?? swm?.getScheme() ?? '');
    final isLayoutToggled = useState(false);
    final swmNotifier = useState(swm);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final startX = useState(0.0);
    final timer = useState<Timer?>(null);

    final searchFunc = useCallback(
      (String naddr) {
        if (timer.value != null) {
          timer.value!.cancel();
        }

        if (naddr.trim().isEmpty) {
          swmNotifier.value = null;
          isLayoutToggled.value = false;
          return;
        }

        timer.value = Timer(
          const Duration(seconds: 1),
          () async {
            try {
              swmNotifier.value = await getSmartWidgetFromNaddr(naddr);
            } catch (e) {
              lg.i(e);
              swmNotifier.value = null;
            }

            isLayoutToggled.value = false;
          },
        );
      },
    );

    return Scaffold(
      appBar: CustomAppBar(
        title: viewMode
            ? context.t.smartWidget.capitalizeFirst()
            : context.t.smartWidgetChecker.capitalizeFirst(),
        notElevated: true,
      ),
      body: Column(
        children: [
          if (!viewMode) ...[
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            _textfield(naddrTextEditingController, context, naddNotifier,
                isLayoutToggled, swmNotifier, searchFunc),
          ],
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Expanded(
            child: isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _widgetCheckerComponent(
                          isLayoutToggled, naddNotifier, isTablet, swmNotifier),
                      _widgetCheckerLayout(swmNotifier),
                    ],
                  )
                : widgetLayoutBuilder(startX, isLayoutToggled, naddNotifier,
                    isTablet, swmNotifier),
          ),
        ],
      ),
    );
  }

  LayoutBuilder widgetLayoutBuilder(
      ValueNotifier<double> startX,
      ValueNotifier<bool> isLayoutToggled,
      ValueNotifier<String> naddNotifier,
      bool isTablet,
      ValueNotifier<SmartWidget?> swmNotifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: (details) {
            startX.value = details.localPosition.dx;
          },
          onHorizontalDragUpdate: (details) {
            final double currentX = details.localPosition.dx;
            if (currentX > startX.value) {
              isLayoutToggled.value = false;
            } else if (currentX < startX.value) {
              isLayoutToggled.value = true;
            }
          },
          onHorizontalDragEnd: (details) {
            startX.value = 0;
          },
          child: Stack(
            children: [
              _lbWidgetCheckerComponents(isLayoutToggled, constraints,
                  naddNotifier, isTablet, swmNotifier),
              _lbWidgetCheckerLayout(
                  isLayoutToggled, constraints, swmNotifier, context),
            ],
          ),
        );
      },
    );
  }

  AnimatedPositioned _lbWidgetCheckerLayout(
      ValueNotifier<bool> isLayoutToggled,
      BoxConstraints constraints,
      ValueNotifier<SmartWidget?> swmNotifier,
      BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: isLayoutToggled.value ? 10.w : 100.w,
      height: constraints.maxHeight,
      curve: Curves.easeInOut,
      width: 88.w,
      child: swmNotifier.value != null
          ? WidgetCheckerLayout(
              smartWidgetModel: swmNotifier.value!,
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    kDefaultPadding / 2,
                  ),
                  alignment: Alignment.topCenter,
                  margin: const EdgeInsets.only(
                    right: kDefaultPadding,
                    top: kDefaultPadding * 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 2,
                    ),
                    color: Theme.of(context).primaryColorLight,
                  ),
                  child: EmptyList(
                    description:
                        context.t.noComponentsDisplayed.capitalizeFirst(),
                    icon: FeatureIcons.swChecker,
                  ),
                ),
              ],
            ),
    );
  }

  AnimatedPositioned _lbWidgetCheckerComponents(
      ValueNotifier<bool> isLayoutToggled,
      BoxConstraints constraints,
      ValueNotifier<String> naddNotifier,
      bool isTablet,
      ValueNotifier<SmartWidget?> swmNotifier) {
    return AnimatedPositioned(
      duration: const Duration(
        milliseconds: 300,
      ),
      curve: Curves.easeInOut,
      right: isLayoutToggled.value ? 90.w : 0.0,
      height: constraints.maxHeight,
      width: constraints.maxWidth,
      child: GestureDetector(
        onTap:
            isLayoutToggled.value ? () => isLayoutToggled.value = false : null,
        child: AbsorbPointer(
          absorbing: isLayoutToggled.value,
          child: WidgetCheckerComponent(
            naddNotifier: naddNotifier.value,
            isTablet: isTablet,
            swm: swmNotifier.value,
            isLayoutToggled: isLayoutToggled.value,
            viewMode: viewMode,
            onToggle: () {
              isLayoutToggled.value = true;
            },
          ),
        ),
      ),
    );
  }

  Expanded _widgetCheckerLayout(ValueNotifier<SmartWidget?> swmNotifier) {
    return Expanded(
      child: Builder(builder: (context) {
        return swmNotifier.value != null
            ? WidgetCheckerLayout(
                smartWidgetModel: swmNotifier.value!,
              )
            : Container(
                padding: const EdgeInsets.all(
                  kDefaultPadding / 2,
                ),
                margin: const EdgeInsets.only(
                  right: kDefaultPadding,
                  top: kDefaultPadding * 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding / 2,
                  ),
                  color: Theme.of(context).cardColor,
                ),
                child: EmptyList(
                  description:
                      context.t.noComponentsDisplayed.capitalizeFirst(),
                  icon: FeatureIcons.swChecker,
                ),
              );
      }),
    );
  }

  Expanded _widgetCheckerComponent(
      ValueNotifier<bool> isLayoutToggled,
      ValueNotifier<String> naddNotifier,
      bool isTablet,
      ValueNotifier<SmartWidget?> swmNotifier) {
    return Expanded(
      child: GestureDetector(
        onTap:
            isLayoutToggled.value ? () => isLayoutToggled.value = false : null,
        child: AbsorbPointer(
          absorbing: isLayoutToggled.value,
          child: WidgetCheckerComponent(
            naddNotifier: naddNotifier.value,
            isTablet: isTablet,
            swm: swmNotifier.value,
            viewMode: viewMode,
            isLayoutToggled: isLayoutToggled.value,
            onToggle: () {
              isLayoutToggled.value = true;
            },
          ),
        ),
      ),
    );
  }

  Padding _textfield(
      TextEditingController naddrTextEditingController,
      BuildContext context,
      ValueNotifier<String> naddNotifier,
      ValueNotifier<bool> isLayoutToggled,
      ValueNotifier<SmartWidget?> swmNotifier,
      Function(String) searchFunc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
      child: TextFormField(
        controller: naddrTextEditingController,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: context.t.naddr.capitalizeFirst(),
          prefixIcon: SizedBox(
            width: 10,
            height: 10,
            child: Center(
              child: SvgPicture.asset(
                FeatureIcons.search,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          suffixIcon: CustomIconButton(
            onClicked: () {
              naddrTextEditingController.clear();
              naddNotifier.value = '';
              isLayoutToggled.value = false;
              swmNotifier.value = null;
            },
            icon: FeatureIcons.closeRaw,
            size: 20,
            vd: -4,
            backgroundColor: Theme.of(context).cardColor,
          ),
        ),
        onChanged: (naddrVal) {
          naddNotifier.value = naddrVal;
          isLayoutToggled.value = false;
          searchFunc.call(naddrVal);
        },
      ),
    );
  }
}

class WidgetCheckerLayout extends StatelessWidget {
  const WidgetCheckerLayout({
    super.key,
    required this.smartWidgetModel,
  });

  final SmartWidget smartWidgetModel;

  @override
  Widget build(BuildContext context) {
    final List<Widget> grids = [];
    final box = smartWidgetModel.smartWidgetBox;

    grids.add(
      WidgetCheckerRow(
        mapKey: context.t.image.capitalizeFirst(),
        mapValue: box.image.url,
        mapStatus: getPropertyStatus(box.image),
        color: Theme.of(context).primaryColor,
      ),
    );

    grids.add(
      const Divider(
        height: kDefaultPadding,
      ),
    );

    if (box.inputField != null) {
      grids.add(
        WidgetCheckerRow(
          mapKey: context.t.inputField.capitalizeFirst(),
          mapValue: box.inputField!.placeholder,
          mapStatus: getPropertyStatus(box.inputField!),
          color: Theme.of(context).primaryColor,
        ),
      );

      grids.add(
        const Divider(
          height: kDefaultPadding,
        ),
      );
    }

    if (box.buttons.isNotEmpty) {
      for (int i = 0; i < box.buttons.length; i++) {
        final button = box.buttons[i];

        grids.add(
          Row(
            spacing: kDefaultPadding / 2,
            children: [
              Text(
                '${context.t.button.capitalizeFirst()} $i',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
              Expanded(
                child: Text(
                  '↴',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              )
            ],
          ),
        );
        grids.add(
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
        );
        grids.add(
          Padding(
            padding: const EdgeInsets.only(left: kDefaultPadding / 1.5),
            child: Column(
              spacing: kDefaultPadding / 4,
              children: [
                WidgetCheckerRow(
                  mapKey: context.t.text.capitalizeFirst(),
                  mapValue: button.text,
                  mapStatus: button.text.isNotEmpty
                      ? PropertyStatus.valid
                      : PropertyStatus.invalid,
                  color: Theme.of(context).primaryColor,
                ),
                WidgetCheckerRow(
                  mapKey: context.t.type.capitalizeFirst(),
                  mapValue: button.type.name.capitalizeFirst(),
                  mapStatus: SWBType.values.contains(button.type)
                      ? PropertyStatus.valid
                      : PropertyStatus.invalid,
                  color: Theme.of(context).primaryColor,
                ),
                WidgetCheckerRow(
                  mapKey: context.t.url.capitalizeFirst(),
                  mapValue: button.url,
                  mapStatus: getPropertyStatus(button),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        );

        if (i < box.buttons.length - 1) {
          grids.add(
            const Divider(
              height: kDefaultPadding,
            ),
          );
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.t.metadata.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 3,
          ),
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: Theme.of(context).cardColor,
            ),
            width: double.infinity,
            child: Column(
              children: [
                getMetadataRow(
                  content: smartWidgetModel.title,
                  title: context.t.title.capitalizeFirst(),
                  context: context,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                getMetadataRow(
                  content: dateFormat3.format(smartWidgetModel.createdAt),
                  title: context.t.createdAt.capitalizeFirst(),
                  context: context,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                getMetadataRow(
                  content: smartWidgetModel.identifier,
                  title: context.t.identifier.capitalizeFirst(),
                  context: context,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 1.5,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.t.widgets.capitalizeFirst(),
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 3,
          ),
          Container(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 2),
              color: Theme.of(context).cardColor,
            ),
            width: double.infinity,
            child: Column(
              children: [
                ...grids,
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
        ],
      ),
    );
  }

  Row getMetadataRow({
    required String title,
    required String content,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
        ),
        Expanded(
          child: Text(
            content,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(),
          ),
        ),
      ],
    );
  }
}

class WidgetCheckerRow extends StatelessWidget {
  const WidgetCheckerRow({
    super.key,
    required this.mapKey,
    required this.mapValue,
    required this.mapStatus,
    required this.color,
  });

  final String mapKey;
  final String mapValue;
  final PropertyStatus mapStatus;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isEmpty = mapValue.isEmpty || mapValue == 'null';
    final icon = addIcon(mapKey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kDefaultPadding / 8),
      child: Row(
        children: [
          Text(
            '$mapKey ',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          if (icon)
            Expanded(
              child: Row(
                children: [
                  if (mapStatus == PropertyStatus.valid &&
                      mapValue.isNotEmpty &&
                      mapValue != '[]' &&
                      mapValue != 'null')
                    Text(
                      '↴',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                ],
              ),
            )
          else
            Expanded(
              child: Text(
                isEmpty ? 'N/A' : mapValue,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: isEmpty
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColorDark,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(
            width: kDefaultPadding / 3,
          ),
          SvgPicture.asset(
            mapStatus == PropertyStatus.valid
                ? FeatureIcons.widgetCorrect
                : mapStatus == PropertyStatus.invalid
                    ? FeatureIcons.widgetInfo
                    : FeatureIcons.widgetWrong,
            width: 17,
            height: 17,
          )
        ],
      ),
    );
  }

  bool addIcon(String keyUsed) {
    return keyUsed == 'components' ||
        keyUsed == 'metadata' ||
        keyUsed == 'left_side' ||
        keyUsed == 'right_side';
  }
}

class WidgetCheckerComponent extends HookWidget {
  const WidgetCheckerComponent({
    super.key,
    required this.naddNotifier,
    required this.onToggle,
    required this.isLayoutToggled,
    required this.isTablet,
    required this.viewMode,
    this.swm,
  });

  final String naddNotifier;
  final Function() onToggle;
  final SmartWidget? swm;
  final bool isLayoutToggled;
  final bool isTablet;
  final bool viewMode;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      children: [
        Builder(
          builder: (context) {
            if (naddNotifier.isEmpty) {
              return _swInfoRow(context);
            } else {
              if (naddNotifier.startsWith('naddr')) {
                if (swm == null) {
                  return EmptyList(
                    description: context.t.notFindSMwithAddr.capitalizeFirst(),
                    icon: FeatureIcons.smartWidget,
                  );
                } else {
                  return _actionButton();
                }
              } else {
                return EmptyList(
                  description: context.t.notFindSMwithAddr.capitalizeFirst(),
                  icon: FeatureIcons.smartWidget,
                );
              }
            }
          },
        ),
        const SizedBox(
          height: kBottomNavigationBarHeight,
        ),
      ],
    );
  }

  Column _actionButton() {
    return Column(
      children: [
        if (!isTablet && !viewMode) ...[
          Align(
            alignment: Alignment.centerRight,
            child: SmallRectangularButton(
              onClick: onToggle,
              turns: 0,
              icon: FeatureIcons.layers,
              backgroundColor: null,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
        ],
        SmartWidgetComponent(
          smartWidget: swm!,
        ),
      ],
    );
  }

  Column _swInfoRow(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Image.asset(
          Images.smartWidget,
          width: 50.w,
        ),
        Text(
          context.t.smartWidgetChecker.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).primaryColorDark,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          context.t.enterSMaddr.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).hintColor,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
