// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../models/smart_widgets_components.dart';
import '../../../../utils/utils.dart';
import '../../../smart_widgets_view/widgets/smart_widget_container.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/empty_list.dart';

class SmartWidgetsDrafts extends HookWidget {
  const SmartWidgetsDrafts({
    super.key,
    required this.onSmartWidgetDraftSelected,
    required this.onSmartWidgetPublished,
  });

  final Function(SWAutoSaveModel) onSmartWidgetDraftSelected;
  final Function(SWAutoSaveModel) onSmartWidgetPublished;

  @override
  Widget build(BuildContext context) {
    final draftsList = useState<Map<String, SWAutoSaveModel>>({
      for (final sw in (nostrRepository.userDrafts?.smartWidgetsDraft.entries ??
          const Iterable.empty()))
        sw.key: SWAutoSaveModel.fromJson(sw.value)
    });

    return Container(
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
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.40,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const ModalBottomSheetHandle(),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                context.t.smartWidgetsDrafts,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Expanded(
                child: draftsList.value.isEmpty
                    ? EmptyList(
                        description: context.t.noSmartWidget,
                        icon: FeatureIcons.smartWidget,
                      )
                    : Builder(
                        builder: (context) {
                          final list = draftsList.value.values.toList();

                          return ListView.separated(
                            controller: scrollController,
                            itemCount: list.length,
                            padding: const EdgeInsets.symmetric(
                              horizontal: kDefaultPadding / 2,
                              vertical: kDefaultPadding * 1.5,
                            ),
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            itemBuilder: (context, index) {
                              final sw = list[index];

                              final box = SmartWidgetBox.fromMap(
                                sw.content,
                              );

                              return _draftItem(box, context, sw, draftsList);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Column _draftItem(
      SmartWidgetBox box,
      BuildContext context,
      SWAutoSaveModel sw,
      ValueNotifier<Map<String, SWAutoSaveModel>> draftsList) {
    return Column(
      children: [
        SmartWidgetComponent(
          smartWidget: SmartWidget(
            id: '',
            createdAt: DateTime.now(),
            pubkey: '',
            image: '',
            identifier: '',
            client: '',
            title: '',
            smartWidgetBox: box,
            stringifiedEvent: '',
            icon: '',
            type: SWType.basic,
            keywords: const [],
          ),
          disableWidget: true,
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onSmartWidgetPublished.call(sw);
              },
              style: TextButton.styleFrom(
                visualDensity: const VisualDensity(
                  vertical: -0.5,
                ),
                backgroundColor: Theme.of(context).cardColor,
              ),
              child: Text(
                context.t.publish.capitalizeFirst(),
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(color: Theme.of(context).primaryColorDark),
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: () {
                onSmartWidgetDraftSelected.call(sw);
                Navigator.pop(context);
              },
              icon: FeatureIcons.editWidget,
              size: 20,
              backgroundColor: Theme.of(context).cardColor,
            ),
            const SizedBox(
              width: kDefaultPadding / 4,
            ),
            CustomIconButton(
              onClicked: () {
                nostrRepository.deleteSmartWidgetDraft(
                  id: sw.id,
                );
                draftsList.value.remove(sw.id);
                draftsList.value = Map<String, SWAutoSaveModel>.from(
                  draftsList.value..remove(sw.id),
                );
              },
              icon: FeatureIcons.trash,
              size: 20,
              backgroundColor: Theme.of(context).cardColor,
            ),
          ],
        )
      ],
    );
  }
}

class NoSmartWidgetContainer extends StatelessWidget {
  const NoSmartWidgetContainer({
    super.key,
    this.backgroundColor,
  });

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      ),
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      child: Text(
        context.t.smartWidgetConvention.capitalizeFirst(),
        style: Theme.of(context).textTheme.labelMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
