import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../logic/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../add_content_specification_views/add_smart_widget_specification_view.dart';
import '../related_adding_views/smart_widget_widgets/smart_widget_specifications.dart';
import '../widgets/add_content_appbar.dart';
import 'add_article_main_view.dart';

class AddSmartWidgetMainView extends HookWidget {
  const AddSmartWidgetMainView({
    super.key,
    this.smartWidgetModel,
    this.isCloning,
    this.selectFirstSmartWidgetDraft,
  });

  final SmartWidget? smartWidgetModel;
  final bool? isCloning;
  final bool? selectFirstSmartWidgetDraft;

  @override
  Widget build(BuildContext context) {
    final toggleFrameSpecifications = useState(false);
    final bg = Theme.of(context).primaryColorLight.toHex();
    final signer = useState(currentSigner!);
    final components = <Widget>[];

    components.add(
      BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
        builder: (context, state) {
          return Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: AddContentAppbar(
              actionButtonText: context.t.next.capitalize(),
              isActionButtonEnabled: !state.isOnboarding,
              extraRight: Padding(
                padding: const EdgeInsets.only(left: kDefaultPadding / 3),
                child: ContentAccountsSwitcher(
                  signer: signer,
                ),
              ),
              extra: state.isOnboarding
                  ? null
                  : _toggleFrame(toggleFrameSpecifications, context),
              onActionClicked: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return BlocProvider<WriteSmartWidgetCubit>.value(
                      value: context.read<WriteSmartWidgetCubit>(),
                      child: AddSmartWidgetSpecificationView(
                        signer: signer.value,
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
            ),
          );
        },
      ),
    );

    components.add(
      Expanded(
        child: BlocBuilder<AddContentCubit, AddContentState>(
          builder: (context, state) {
            return FrameSpecifications(
              toggleView: toggleFrameSpecifications.value,
            );
          },
        ),
      ),
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: nostrRepository.mainCubit,
        ),
        BlocProvider(
          create: (context) => WriteSmartWidgetCubit(
            uuId: uuid.v4(),
            backgroundColor: bg,
            sm: smartWidgetModel,
            isCloning: isCloning,
            selectFirstSmartWidgetDraft: selectFirstSmartWidgetDraft,
          ),
        ),
      ],
      child: Column(
        children: components,
      ),
    );
  }

  Row _toggleFrame(
      ValueNotifier<bool> toggleFrameSpecifications, BuildContext context) {
    return Row(
      children: [
        CustomIconButton(
          icon: toggleFrameSpecifications.value
              ? FeatureIcons.visible
              : FeatureIcons.notVisible,
          backgroundColor: Theme.of(context).cardColor,
          onClicked: () {
            toggleFrameSpecifications.value = !toggleFrameSpecifications.value;
          },
          size: 20,
          vd: -1,
        ),
        const SizedBox(
          width: kDefaultPadding / 2,
        ),
      ],
    );
  }
}
