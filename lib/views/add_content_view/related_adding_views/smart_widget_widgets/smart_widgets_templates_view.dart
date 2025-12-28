// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../logic/write_smart_widget_cubit/sm_templates_cubit/smart_widget_templates_cubit.dart';
import '../../../../models/smart_widgets_components.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/empty_list.dart';

class SmartWidgetTemplatesView extends StatelessWidget {
  const SmartWidgetTemplatesView({
    super.key,
    required this.onSmartWidgetSelected,
  });

  final Function(SmartWidgetBox) onSmartWidgetSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SmartWidgetTemplatesCubit()..getSmartWidgetsTemplates(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(kDefaultPadding),
            topRight: Radius.circular(kDefaultPadding),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child:
            BlocBuilder<SmartWidgetTemplatesCubit, SmartWidgetTemplatesState>(
          builder: (context, state) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.40,
              maxChildSize: 0.85,
              expand: false,
              builder: (context, scrollController) =>
                  _itemColumn(scrollController, context, state),
            );
          },
        ),
      ),
    );
  }

  Column _itemColumn(ScrollController scrollController, BuildContext context,
      SmartWidgetTemplatesState state) {
    return Column(
      children: [
        const ModalBottomSheetHandle(),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            children: [
              Text(
                context.t.smartWidgetsTemplates.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              Divider(
                color: Theme.of(context).dividerColor,
                indent: kDefaultPadding / 2,
                endIndent: kDefaultPadding / 2,
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              _smartWidgetsItems(state)
            ],
          ),
        ),
      ],
    );
  }

  Builder _smartWidgetsItems(SmartWidgetTemplatesState state) {
    return Builder(
      builder: (context) {
        if (state.updatingState == UpdatingState.progress) {
          return const Padding(
            padding: EdgeInsets.all(kDefaultPadding),
          );
        } else if (state.smartWidgets.isEmpty) {
          return EmptyList(
            description: context.t.noTemplatesCanBeFound.capitalizeFirst(),
            icon: FeatureIcons.templates,
          );
        } else {
          return GridView.builder(
            primary: false,
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: kDefaultPadding / 4,
              childAspectRatio: 16 / 12,
              mainAxisSpacing: kDefaultPadding / 4,
            ),
            itemBuilder: (context, index) {
              final swt = state.smartWidgets[index];

              return SWTemplateContainer(
                template: swt,
                onClicked: () async {
                  final sw = await swt.getCurrentSmartWidget();

                  if (sw != null && context.mounted) {
                    YNavigator.pushPage(
                      context,
                      (context) => SmartWidgetChecker(
                        swm: sw,
                        naddr: sw.getScheme(),
                      ),
                    );
                  }
                },
                onSmartWidgetSelected: () async {
                  final sw = await swt.getCurrentSmartWidget();

                  if (sw != null && context.mounted) {
                    onSmartWidgetSelected.call(
                      sw.smartWidgetBox,
                    );
                    YNavigator.pop(context);
                  }
                },
              );
            },
            itemCount: state.smartWidgets.length,
          );
        }
      },
    );
  }
}

class SWTemplateContainer extends StatelessWidget {
  const SWTemplateContainer({
    super.key,
    required this.template,
    required this.onSmartWidgetSelected,
    required this.onClicked,
  });

  final SmartWidgetTemplate template;
  final Function() onSmartWidgetSelected;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      child: SizedBox(
        height: 50,
        child: Column(
          children: [
            _actionsStack(context),
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            Text(
              template.title,
              maxLines: 2,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  AspectRatio _actionsStack(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: CommonThumbnail(
              image: template.thumbnail,
              width: double.infinity,
              radius: kDefaultPadding / 2,
              height: 0,
            ),
          ),
          Positioned(
            top: kDefaultPadding / 3,
            right: kDefaultPadding / 3,
            child: Row(
              children: [
                CustomIconButton(
                  onClicked: onClicked,
                  icon: FeatureIcons.informationRaw,
                  size: 10,
                  vd: -4,
                  iconColor: kWhite,
                  backgroundColor: Theme.of(context).cardColor,
                ),
                const SizedBox(
                  width: kDefaultPadding / 8,
                ),
                CustomIconButton(
                  onClicked: () {
                    onSmartWidgetSelected.call();
                  },
                  icon: FeatureIcons.addRaw,
                  size: 10,
                  vd: -4,
                  backgroundColor: Theme.of(context).cardColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
