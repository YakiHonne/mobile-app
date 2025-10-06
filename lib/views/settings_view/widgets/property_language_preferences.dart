// ignore_for_file: use_build_context_synchronously, unused_element

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../../../logic/localization_cubit/localization_cubit.dart';
import '../../../models/translate_services_model.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/dotted_container.dart';
import 'settings_text.dart';

// ==========================================
// MAIN LANGUAGE PREFERENCES SCREEN
// ==========================================

class PropertyLanguagePreferences extends StatelessWidget {
  PropertyLanguagePreferences({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Language preference view');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: context.t.languagePreferences.capitalizeFirst(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(kDefaultPadding / 2),
            children: [
              _buildDescription(context),
              const _SectionDivider(),
              const _AppLanguageSection(),
              const SizedBox(height: kDefaultPadding),
              const ContentTranslation(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      context.t.settingsLanguageDesc,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).highlightColor,
          ),
    );
  }
}

// ==========================================
// REUSABLE COMPONENTS
// ==========================================

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: kDefaultPadding * 1.5,
      thickness: 0.5,
    );
  }
}

class _CustomPullDownButton extends StatelessWidget {
  const _CustomPullDownButton({
    required this.buttonText,
    required this.itemBuilder,
    this.iconPath,
    this.onTap,
  });

  final String buttonText;
  final String? iconPath;
  final List<PullDownMenuEntry> Function(BuildContext) itemBuilder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PullDownButton(
      animationBuilder: (context, state, child) => child,
      routeTheme: PullDownMenuRouteTheme(
        backgroundColor: Theme.of(context).cardColor,
      ),
      itemBuilder: itemBuilder,
      buttonBuilder: (context, showMenu) => GestureDetector(
        onTap: onTap ?? showMenu,
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              if (iconPath != null) ...[
                SvgPicture.asset(iconPath!, width: 20, height: 20),
                const SizedBox(width: kDefaultPadding / 4),
              ],
              Text(buttonText, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: kDefaultPadding / 4),
              const Icon(CupertinoIcons.chevron_up_chevron_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// APP LANGUAGE SECTION
// ==========================================

class _AppLanguageSection extends StatelessWidget {
  const _AppLanguageSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.appLanguage.capitalizeFirst(),
            description: context.t.appLangDesc,
          ),
        ),
        const SizedBox(width: kDefaultPadding / 4),
        _CustomPullDownButton(
          buttonText: availableLocales[
              LocaleSettings.currentLocale.languageCode]!['name']!,
          iconPath: availableLocales[
              LocaleSettings.currentLocale.languageCode]!['icon'],
          itemBuilder: _buildLanguageMenuItems,
        ),
      ],
    );
  }

  List<PullDownMenuEntry> _buildLanguageMenuItems(BuildContext context) {
    return List.generate(
      availableLocales.length,
      (index) {
        final localeEntry = availableLocales.entries.toList()[index];
        final name = localeEntry.value['name']!;
        final icon = localeEntry.value['icon']!;
        final isSelected = availableLocales[
                LocaleSettings.currentLocale.languageCode]!['name']! ==
            name;

        return PullDownMenuItem.selectable(
          onTap: () {
            context
                .read<LocalizationCubit>()
                .setLanguage(localeEntry.key.toLocale());
          },
          selected: isSelected,
          title: name.capitalize(),
          iconWidget: SvgPicture.asset(icon),
          itemTheme: PullDownMenuItemTheme(
            textStyle: Theme.of(context).textTheme.labelMedium,
          ),
        );
      },
    );
  }
}

// ==========================================
// CONTENT TRANSLATION SECTION
// ==========================================

class ContentTranslation extends HookWidget {
  const ContentTranslation({super.key});

  @override
  Widget build(BuildContext context) {
    final displayApiKey = useState(false);
    final apiKeyController = _useApiKeyController();

    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        return Column(
          children: [
            _TranslationServiceSelector(apiKeyController: apiKeyController),
            if (!state.translationServices.isUsingCustomService) ...[
              const SizedBox(height: kDefaultPadding),
              _BuiltInServiceConfiguration(
                displayApiKey: displayApiKey,
                apiKeyController: apiKeyController,
              ),
            ],
          ],
        );
      },
    );
  }

  TextEditingController _useApiKeyController() {
    final tServices = localizationCubit.state.translationServices;
    return useTextEditingController(
      text: tServices.apiKeys[tServices.isUsingCustomService
              ? tServices.customServiceName!
              : tServices.builtInService!.name] ??
          '',
    );
  }
}

// ==========================================
// TRANSLATION SERVICE SELECTOR
// ==========================================

class _TranslationServiceSelector extends StatelessWidget {
  const _TranslationServiceSelector({required this.apiKeyController});
  final TextEditingController apiKeyController;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.contentTranslation.capitalizeFirst(),
            description: context.t.contentTransDesc,
          ),
        ),
        BlocBuilder<LocalizationCubit, LocalizationState>(
          builder: (context, state) {
            return _CustomPullDownButton(
              buttonText: _TranslationServiceHelper.getSelectedTsTitle(
                state.translationServices.selectedTranslationService,
              ),
              itemBuilder: (context) =>
                  _buildTranslationServiceItems(context, state),
            );
          },
        ),
      ],
    );
  }

  List<PullDownMenuEntry> _buildTranslationServiceItems(
    BuildContext context,
    LocalizationState state,
  ) {
    return [
      // Default Services Header
      PullDownMenuItem(
        onTap: () {},
        title: context.t.defaultServices.capitalizeFirst(),
        itemTheme: PullDownMenuItemTheme(
          textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      // Built-in Services
      ..._buildBuiltInServiceItems(context, state),
      const PullDownMenuDivider.large(),
      // Custom Services
      _buildCustomServiceHeader(context),
      ..._buildCustomServiceItems(context, state),
    ];
  }

  List<PullDownMenuEntry> _buildBuiltInServiceItems(
    BuildContext context,
    LocalizationState state,
  ) {
    return List.generate(
      translationServicesNames.length,
      (index) {
        final name = translationServicesNames[index];
        final service = _TranslationServiceHelper.getServiceByIndex(index);

        return PullDownMenuItem.selectable(
          onTap: () =>
              _handleBuiltInServiceSelection(context, state, service, index),
          selected: !state.translationServices.isUsingCustomService &&
              _TranslationServiceHelper.isTsSelected(
                state.translationServices.builtInService!,
                name,
              ),
          title: name,
          itemTheme: PullDownMenuItemTheme(
            textStyle: Theme.of(context).textTheme.labelMedium,
          ),
        );
      },
    );
  }

  PullDownMenuItem _buildCustomServiceHeader(BuildContext context) {
    return PullDownMenuItem(
      onTap: () => _showCustomServiceModal(context),
      title: context.t.customServices.capitalizeFirst(),
      itemTheme: PullDownMenuItemTheme(
        textStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      iconWidget: SvgPicture.asset(
        FeatureIcons.settings,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(
          Theme.of(context).primaryColorDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  List<PullDownMenuEntry> _buildCustomServiceItems(
    BuildContext context,
    LocalizationState state,
  ) {
    if (state.translationServices.customServices.isEmpty) {
      return [];
    }

    return List.generate(
      state.translationServices.customServices.length,
      (index) {
        final service =
            state.translationServices.customServices.entries.toList()[index];
        final name = TranslationServices.getCustomUrlName(service.value);

        return PullDownMenuItem.selectable(
          onTap: () {
            context.read<LocalizationCubit>().setCustomTranslationService(
                  url: service.value,
                  isFree: service.key.contains('free'),
                );
          },
          selected: state.translationServices.selectedTranslationService ==
              CustomService(service.key),
          title: name,
          itemTheme: PullDownMenuItemTheme(
            textStyle: Theme.of(context).textTheme.labelMedium,
          ),
        );
      },
    );
  }

  void _handleBuiltInServiceSelection(
    BuildContext context,
    LocalizationState state,
    TranslationsServices service,
    int index,
  ) {
    context.read<LocalizationCubit>().setDefaultTranslationService(ts: service);
    apiKeyController.text =
        state.translationServices.apiKeys[service.name] ?? '';
  }

  void _showCustomServiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const ManageCustomServices(),
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}

// ==========================================
// BUILT-IN SERVICE CONFIGURATION
// ==========================================

class _BuiltInServiceConfiguration extends StatelessWidget {
  const _BuiltInServiceConfiguration({
    required this.displayApiKey,
    required this.apiKeyController,
  });
  final ValueNotifier<bool> displayApiKey;
  final TextEditingController apiKeyController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        final service = state.translationServices.builtInService!;
        final showPlanSelector = service != TranslationsServices.wineTranslate;
        final showApiKeyField =
            service != TranslationsServices.libreTranslateFree;

        return Column(
          children: [
            if (showPlanSelector) ...[
              _PlanSelector(apiKeyController: apiKeyController),
              const SizedBox(height: kDefaultPadding / 2),
            ],
            if (showApiKeyField)
              _ApiKeySection(
                displayApiKey: displayApiKey,
                apiKeyController: apiKeyController,
                service: service,
              ),
          ],
        );
      },
    );
  }
}

// ==========================================
// PLAN SELECTOR
// ==========================================

class _PlanSelector extends StatelessWidget {
  const _PlanSelector({required this.apiKeyController});
  final TextEditingController apiKeyController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        return Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: TitleDescriptionComponent(
                title: context.t.plan.capitalizeFirst(),
                description: context.t.planDesc,
              ),
            ),
            _CustomPullDownButton(
              buttonText: _TranslationServiceHelper.getPlanTitle(
                state.translationServices.builtInService!,
                context,
              ),
              itemBuilder: (context) => _buildPlanItems(context, state),
            ),
          ],
        );
      },
    );
  }

  List<PullDownMenuEntry> _buildPlanItems(
      BuildContext context, LocalizationState state) {
    return List.generate(2, (index) {
      final isFree = index == 0;

      return PullDownMenuItem.selectable(
        onTap: () => _handlePlanSelection(context, state, isFree),
        selected: _TranslationServiceHelper.isPlanSelected(
          state.translationServices.builtInService!,
          index,
        ),
        title: isFree
            ? context.t.free.capitalizeFirst()
            : context.t.pro.capitalizeFirst(),
        itemTheme: PullDownMenuItemTheme(
          textStyle: Theme.of(context).textTheme.labelMedium,
        ),
      );
    });
  }

  void _handlePlanSelection(
      BuildContext context, LocalizationState state, bool isFree) {
    final currentService = state.translationServices.builtInService!;
    final newService =
        _TranslationServiceHelper.getServiceForPlan(currentService, isFree);

    context
        .read<LocalizationCubit>()
        .setDefaultTranslationService(ts: newService);
    apiKeyController.text =
        state.translationServices.apiKeys[newService.name] ?? '';
  }
}

// ==========================================
// API KEY SECTION
// ==========================================

class _ApiKeySection extends StatelessWidget {
  const _ApiKeySection({
    required this.displayApiKey,
    required this.apiKeyController,
    required this.service,
  });
  final ValueNotifier<bool> displayApiKey;
  final TextEditingController apiKeyController;
  final TranslationsServices service;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ApiKeyField(
          displayApiKey: displayApiKey,
          apiKeyController: apiKeyController,
          service: service,
        ),
        const SizedBox(height: kDefaultPadding / 4),
        _GetApiKeyButton(service: service),
        const SizedBox(height: kDefaultPadding / 2),
      ],
    );
  }
}

class _ApiKeyField extends StatelessWidget {
  const _ApiKeyField({
    required this.displayApiKey,
    required this.apiKeyController,
    required this.service,
  });
  final ValueNotifier<bool> displayApiKey;
  final TextEditingController apiKeyController;
  final TranslationsServices service;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: apiKeyController,
      style: Theme.of(context).textTheme.bodyMedium,
      obscureText: !displayApiKey.value,
      decoration: InputDecoration(
        hintText: context.t.apiKeyRequired.capitalizeFirst(),
        suffixIcon: CustomIconButton(
          onClicked: () => displayApiKey.value = !displayApiKey.value,
          icon: displayApiKey.value
              ? FeatureIcons.notVisible
              : FeatureIcons.visible,
          size: 20,
          vd: -4,
          backgroundColor: Theme.of(context).cardColor,
        ),
        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
      ),
      onChanged: (apiKey) {
        context.read<LocalizationCubit>().setDefaultTranslationService(
              ts: service,
              apiKey: apiKey,
            );
      },
    );
  }
}

class _GetApiKeyButton extends StatelessWidget {
  const _GetApiKeyButton({required this.service});
  final TranslationsServices service;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        final url = translationServicesApiUrls[service.name];
        if (url != null) {
          openWebPage(url: url);
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: kTransparent,
        visualDensity: VisualDensity.comfortable,
      ),
      child: Text(
        context.t.getApiKey.capitalizeFirst(),
        style:
            Theme.of(context).textTheme.bodyMedium!.copyWith(color: kMainColor),
      ),
    );
  }
}

// ==========================================
// MANAGE CUSTOM SERVICES MODAL
// ==========================================

class ManageCustomServices extends HookWidget {
  const ManageCustomServices({super.key});

  @override
  Widget build(BuildContext context) {
    final displayApiKey = useState(false);
    final apiKeyController = useTextEditingController();
    final urlController = useTextEditingController();
    final paidPlan = useState(false);

    return BlocBuilder<LocalizationCubit, LocalizationState>(
      builder: (context, state) {
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
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
              builder: (context, scrollController) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    if (state.translationServices.customServices.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _ExistingCustomServices(
                            services: state.translationServices.customServices),
                      ),
                    SliverToBoxAdapter(
                      child: _AddNewServiceForm(
                        displayApiKey: displayApiKey,
                        apiKeyController: apiKeyController,
                        urlController: urlController,
                        paidPlan: paidPlan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const ModalBottomSheetHandle(),
        Text(
          context.t.manageAccounts.capitalizeFirst(),
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const Divider(thickness: 0.5, height: kDefaultPadding),
      ],
    );
  }
}

// ==========================================
// EXISTING CUSTOM SERVICES
// ==========================================

class _ExistingCustomServices extends StatelessWidget {
  const _ExistingCustomServices({required this.services});
  final Map<String, String> services;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleDescriptionComponent(
          title: context.t.customServices.capitalizeFirst(),
          description: context.t.customServicesDesc,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: ListView.separated(
            separatorBuilder: (context, index) =>
                const SizedBox(height: kDefaultPadding / 4),
            itemBuilder: (context, index) => _buildServiceItem(context, index),
            itemCount: services.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          ),
        ),
        const Divider(height: kDefaultPadding * 2, thickness: 0.5),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, int index) {
    final service = services.entries.toList()[index];
    final name = TranslationServices.getCustomUrlName(service.value);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.labelLarge),
              Text(
                service.value,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ],
          ),
        ),
        CustomIconButton(
          onClicked: () {
            context
                .read<LocalizationCubit>()
                .deleteCustomTranslationService(key: service.key);
          },
          icon: FeatureIcons.trash,
          size: 18,
          vd: -2,
          backgroundColor: Theme.of(context).cardColor,
        ),
      ],
    );
  }
}

// ==========================================
// ADD NEW SERVICE FORM
// ==========================================

class _AddNewServiceForm extends StatelessWidget {
  const _AddNewServiceForm({
    required this.displayApiKey,
    required this.apiKeyController,
    required this.urlController,
    required this.paidPlan,
  });
  final ValueNotifier<bool> displayApiKey;
  final TextEditingController apiKeyController;
  final TextEditingController urlController;
  final ValueNotifier<bool> paidPlan;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: kDefaultPadding / 4,
      children: [
        _PlanSelectorForCustomService(paidPlan: paidPlan),
        const SizedBox(height: kDefaultPadding / 8),
        _buildUrlField(context),
        _buildApiKeyField(context),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildUrlField(BuildContext context) {
    return TextFormField(
      controller: urlController,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: context.t.url.capitalizeFirst(),
        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
      ),
    );
  }

  Widget _buildApiKeyField(BuildContext context) {
    return TextFormField(
      controller: apiKeyController,
      style: Theme.of(context).textTheme.bodyMedium,
      obscureText: !displayApiKey.value,
      decoration: InputDecoration(
        hintText: context.t.apiKeyRequired.capitalizeFirst(),
        suffixIcon: CustomIconButton(
          onClicked: () => displayApiKey.value = !displayApiKey.value,
          icon: displayApiKey.value
              ? FeatureIcons.notVisible
              : FeatureIcons.visible,
          size: 20,
          vd: -4,
          backgroundColor: Theme.of(context).cardColor,
        ),
        hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).highlightColor,
            ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => _handleAddService(context),
        child: Text(context.t.addService),
      ),
    );
  }

  Future<void> _handleAddService(BuildContext context) async {
    if (urlController.text.isEmpty) {
      BotToastUtils.showError(context.t.urlRequired);
      return;
    }

    await context.read<LocalizationCubit>().setCustomTranslationService(
          isFree: !paidPlan.value,
          url: urlController.text,
          apiKey: apiKeyController.text,
        );

    apiKeyController.clear();
    urlController.clear();
    BotToastUtils.showSuccess(context.t.serviceAdded);
  }
}

class _PlanSelectorForCustomService extends StatelessWidget {
  const _PlanSelectorForCustomService({required this.paidPlan});
  final ValueNotifier<bool> paidPlan;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: TitleDescriptionComponent(
            title: context.t.plan.capitalizeFirst(),
            description: context.t.planDesc,
          ),
        ),
        _CustomPullDownButton(
          buttonText: paidPlan.value
              ? context.t.pro.capitalizeFirst()
              : context.t.free.capitalizeFirst(),
          itemBuilder: (context) => List.generate(2, (index) {
            final isFree = index == 0;
            return PullDownMenuItem.selectable(
              onTap: () => paidPlan.value = !isFree,
              selected: isFree ? !paidPlan.value : paidPlan.value,
              title: isFree
                  ? context.t.free.capitalizeFirst()
                  : context.t.pro.capitalizeFirst(),
              itemTheme: PullDownMenuItemTheme(
                textStyle: Theme.of(context).textTheme.labelMedium,
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ==========================================
// HELPER CLASS
// ==========================================

class _TranslationServiceHelper {
  static bool isPlanSelected(TranslationsServices ts, int index) {
    if (index == 0) {
      return ts == TranslationsServices.libreTranslateFree ||
          ts == TranslationsServices.deeplFree;
    } else if (index == 1) {
      return ts == TranslationsServices.libreTranslatePro ||
          ts == TranslationsServices.deeplPro;
    }
    return false;
  }

  static String getPlanTitle(
      TranslationsServices tServices, BuildContext context) {
    if (tServices == TranslationsServices.libreTranslateFree ||
        tServices == TranslationsServices.deeplFree) {
      return context.t.free.capitalizeFirst();
    } else {
      return context.t.pro.capitalizeFirst();
    }
  }

  static bool isTsSelected(TranslationsServices ts, String title) {
    if (title == translationServicesNames[0]) {
      return ts == TranslationsServices.libreTranslateFree ||
          ts == TranslationsServices.libreTranslatePro;
    } else if (title == translationServicesNames[1]) {
      return ts == TranslationsServices.deeplFree ||
          ts == TranslationsServices.deeplPro;
    } else {
      return ts == TranslationsServices.wineTranslate;
    }
  }

  static String getSelectedTsTitle(ServiceIdentifier ts) {
    if (ts is CustomService) {
      return TranslationServices.getCustomUrlName(ts.serviceId);
    } else {
      final service = (ts as BuiltInService).service;

      if (service == TranslationsServices.libreTranslateFree ||
          service == TranslationsServices.libreTranslatePro) {
        return translationServicesNames[0];
      } else if (service == TranslationsServices.deeplFree ||
          service == TranslationsServices.deeplPro) {
        return translationServicesNames[1];
      } else {
        return translationServicesNames[2];
      }
    }
  }

  static TranslationsServices getServiceByIndex(int index) {
    return index == 0
        ? TranslationsServices.libreTranslateFree
        : index == 1
            ? TranslationsServices.deeplFree
            : TranslationsServices.wineTranslate;
  }

  static TranslationsServices getServiceForPlan(
    TranslationsServices currentService,
    bool isFree,
  ) {
    final isLibre = currentService == TranslationsServices.libreTranslateFree ||
        currentService == TranslationsServices.libreTranslatePro;

    return isFree
        ? (isLibre
            ? TranslationsServices.libreTranslateFree
            : TranslationsServices.deeplFree)
        : (isLibre
            ? TranslationsServices.libreTranslatePro
            : TranslationsServices.deeplPro);
  }
}
