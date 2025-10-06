import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../../logic/write_smart_widget_cubit/write_smart_widget_cubit.dart';
import '../../../../utils/bot_toast_util.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/common_thumbnail.dart';
import '../../../widgets/custom_icon_buttons.dart';
import '../../../widgets/data_providers.dart';
import '../../../widgets/dotted_container.dart';
import '../../../widgets/note_container.dart';

class SmartWidgetAppSpecification extends HookWidget {
  const SmartWidgetAppSpecification({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final onLoading = useState(false);
    final controller = useTextEditingController(
      text: context.read<WriteSmartWidgetCubit>().state.appSmartWidget.url,
    );

    return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      builder: (context, state) {
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
                return _specificationsColumn(
                    context, state, formKey, controller, onLoading);
              },
            ),
          ),
        );
      },
    );
  }

  Column _specificationsColumn(
      BuildContext context,
      WriteSmartWidgetState state,
      GlobalKey<FormState> formKey,
      TextEditingController controller,
      ValueNotifier<bool> onLoading) {
    return Column(
      children: [
        const ModalBottomSheetHandle(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            children: [
              Center(
                child: Text(
                  context.t.app,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              AbsorbPointer(
                absorbing: state.appSmartWidget.isValid(),
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    style: Theme.of(context).textTheme.bodyMedium,
                    validator: fieldValidator.call,
                    decoration: InputDecoration(
                      hintText: context.t.url,
                    ),
                  ),
                ),
              ),
              if (state.appSmartWidget.isValid()) ...[
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                _metadataCard(state, context),
              ],
            ],
          ),
        ),
        _actionButton(state, context, controller, formKey, onLoading),
      ],
    );
  }

  MetadataProvider _metadataCard(
      WriteSmartWidgetState state, BuildContext context) {
    return MetadataProvider(
      pubkey: state.appSmartWidget.pubkey,
      child: (metadata, isNip05Valid) => Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(
            kDefaultPadding / 2,
          ),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Row(
          spacing: kDefaultPadding / 4,
          children: [
            CommonThumbnail(
              image: state.appSmartWidget.icon,
              placeholder: getRandomPlaceholder(
                  input: state.appSmartWidget.icon, isPfp: false),
              width: 50,
              height: 50,
              radius: kDefaultPadding / 2,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: kDefaultPadding / 4,
                children: [
                  Text(state.appSmartWidget.title),
                  ProfileInfoHeader(
                    pubkey: state.appSmartWidget.pubkey,
                    createdAt: DateTime.now(),
                    isMinimised: true,
                  )
                ],
              ),
            ),
            CustomIconButton(
              onClicked: () {
                openApp(
                  context: context,
                  url: state.appSmartWidget.url,
                );
              },
              icon: FeatureIcons.link,
              size: 20,
              backgroundColor: kTransparent,
            ),
          ],
        ),
      ),
    );
  }

  SafeArea _actionButton(
      WriteSmartWidgetState state,
      BuildContext context,
      TextEditingController controller,
      GlobalKey<FormState> formKey,
      ValueNotifier<bool> onLoading) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: kDefaultPadding / 2,
        ),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: TextButton(
              onPressed: () {
                if (state.appSmartWidget.isValid()) {
                  context.read<WriteSmartWidgetCubit>().resetAppSmartWidget();

                  controller.clear();
                } else {
                  if (formKey.currentState!.validate()) {
                    onLoading.value = true;
                    context.read<WriteSmartWidgetCubit>().processAppSmartWidget(
                          url: controller.text,
                          onFailed: () {
                            onLoading.value = false;
                            BotToastUtils.showError(
                                context.t.appCannotVerified);
                          },
                          onSuccess: () {
                            onLoading.value = false;
                            Navigator.of(context).pop();
                          },
                        );
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: state.appSmartWidget.isValid()
                    ? kRed
                    : Theme.of(context).cardColor,
              ),
              child: onLoading.value
                  ? SpinKitCircle(
                      size: 20,
                      color: Theme.of(context).primaryColorDark,
                    )
                  : Text(
                      state.appSmartWidget.isValid()
                          ? context.t.reset.capitalizeFirst()
                          : context.t.verify.capitalizeFirst(),
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: state.appSmartWidget.isValid()
                                ? kWhite
                                : Theme.of(context).primaryColorDark,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SmartWidgetAppSpecificationRow extends HookWidget {
  const SmartWidgetAppSpecificationRow({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final onLoading = useState(false);
    final controller = useTextEditingController(
      text: context.read<WriteSmartWidgetCubit>().state.appSmartWidget.url,
    );

    return BlocBuilder<WriteSmartWidgetCubit, WriteSmartWidgetState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              AbsorbPointer(
                absorbing: state.appSmartWidget.isValid(),
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: controller,
                    validator: fieldValidator.call,
                    decoration: InputDecoration(
                      hintText: context.t.url,
                    ),
                  ),
                ),
              ),
              if (state.appSmartWidget.isValid()) ...[
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                MetadataProvider(
                  pubkey: state.appSmartWidget.pubkey,
                  child: (metadata, isNip05Valid) => Container(
                    padding: const EdgeInsets.all(kDefaultPadding / 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(
                        kDefaultPadding / 2,
                      ),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      spacing: kDefaultPadding / 4,
                      children: [
                        CommonThumbnail(
                          image: state.appSmartWidget.icon,
                          placeholder: getRandomPlaceholder(
                              input: state.appSmartWidget.icon, isPfp: false),
                          width: 50,
                          height: 50,
                          radius: kDefaultPadding / 2,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: kDefaultPadding / 4,
                            children: [
                              Text(state.appSmartWidget.title),
                              ProfileInfoHeader(
                                pubkey: state.appSmartWidget.pubkey,
                                createdAt: DateTime.now(),
                                isMinimised: true,
                              )
                            ],
                          ),
                        ),
                        CustomIconButton(
                          onClicked: () {
                            openApp(
                              context: context,
                              url: state.appSmartWidget.url,
                            );
                          },
                          icon: FeatureIcons.link,
                          size: 20,
                          backgroundColor: kTransparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    if (state.appSmartWidget.isValid()) {
                      context
                          .read<WriteSmartWidgetCubit>()
                          .resetAppSmartWidget();

                      controller.clear();
                    } else {
                      if (formKey.currentState!.validate()) {
                        onLoading.value = true;
                        context
                            .read<WriteSmartWidgetCubit>()
                            .processAppSmartWidget(
                              url: controller.text,
                              onFailed: () {
                                onLoading.value = false;
                                BotToastUtils.showError(
                                  context.t.appCannotVerified,
                                );
                              },
                              onSuccess: () {
                                onLoading.value = false;
                              },
                            );
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: state.appSmartWidget.isValid()
                        ? kRed
                        : Theme.of(context).cardColor,
                  ),
                  child: onLoading.value
                      ? SpinKitCircle(
                          size: 20,
                          color: Theme.of(context).primaryColorDark,
                        )
                      : Text(
                          state.appSmartWidget.isValid()
                              ? context.t.reset.capitalizeFirst()
                              : context.t.verify.capitalizeFirst(),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    color: state.appSmartWidget.isValid()
                                        ? kWhite
                                        : Theme.of(context).primaryColorDark,
                                  ),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
