// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:nostr_core_enhanced/models/app_shared_settings.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../logic/app_settings_manager_cubit/app_settings_manager_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../wallet_view/widgets/user_to_zap_view.dart';
import '../container_boxes.dart';
import '../custom_date_picker.dart';
import '../custom_drop_down.dart';
import '../custom_icon_buttons.dart';
import '../data_providers.dart';
import '../dotted_container.dart';
import '../profile_picture.dart';
import 'discover_filter_list.dart';

class AddDiscoverFilter extends HookWidget {
  const AddDiscoverFilter({super.key, required this.discoverFilter});

  final DiscoverFilter discoverFilter;

  @override
  Widget build(BuildContext context) {
    final title = useTextEditingController(text: discoverFilter.title);
    final includedKeywords = useState(discoverFilter.includedKeywords);
    final excludedKeywords = useState(discoverFilter.excludedKeywords);
    final includedController = useTextEditingController();
    final excludedController = useTextEditingController();
    final postedBy = useState(discoverFilter.postedBy.toSet());
    final hideSensitive = useState(discoverFilter.hideSensitive);
    final includeThumbnail = useState(discoverFilter.inludeThumbnail);
    final articleMinimumWords = useState(discoverFilter.articleFilter.minWords);
    final articleHasMedia = useState(discoverFilter.articleFilter.onlyMedia);
    final videoSource = useState(discoverFilter.videoFilter.source);
    final curationType = useState(discoverFilter.curationFilter.type);
    final curationMinimumItem = useState(
      discoverFilter.curationFilter.minItems,
    );
    final from = useState(discoverFilter.from);
    final to = useState(discoverFilter.to);

    final isLoading = useState(false);

    final titleKey = useMemoized(
      () => GlobalKey<FormState>(),
    );

    final setFilter = useCallback(
      () async {
        if (titleKey.currentState != null &&
            titleKey.currentState!.validate()) {
          final df = DiscoverFilter(
            hideSensitive: hideSensitive.value,
            inludeThumbnail: includeThumbnail.value,
            articleFilter: DiscoverArticleFilter(
              minWords: articleMinimumWords.value,
              onlyMedia: articleHasMedia.value,
            ),
            curationFilter: DiscoverCurationFilter(
              type: curationType.value,
              minItems: curationMinimumItem.value,
            ),
            videoFilter: DiscoverVideoFilter(
              source: videoSource.value,
            ),
            id: discoverFilter.isDefault() ? uuid.v4() : discoverFilter.id,
            title: title.text,
            includedKeywords: includedKeywords.value,
            excludedKeywords: excludedKeywords.value,
            postedBy: postedBy.value.toList(),
            from: from.value,
            to: to.value,
          );

          isLoading.value = true;

          if (discoverFilter.isDefault()) {
            await appSettingsManagerCubit.addDiscoverFilter(filter: df);
          } else {
            await appSettingsManagerCubit.updateDiscoverFilter(filter: df);
          }

          isLoading.value = false;

          YNavigator.pop(context);
        }
      },
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Column(
              children: [
                _appBar(),
                Expanded(
                  child: _content(
                      context,
                      controller,
                      titleKey,
                      title,
                      from,
                      to,
                      includedController,
                      excludedKeywords,
                      includedKeywords,
                      excludedController,
                      hideSensitive,
                      includeThumbnail,
                      postedBy,
                      articleMinimumWords,
                      articleHasMedia,
                      videoSource,
                      curationType,
                      curationMinimumItem),
                ),
                Container(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom / 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: RegularLoadingButton(
                          title: discoverFilter.isDefault()
                              ? context.t.add.capitalizeFirst()
                              : context.t.update.capitalizeFirst(),
                          isLoading: isLoading.value,
                          onClicked: setFilter,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ScrollShadow _content(
      BuildContext context,
      ScrollController controller,
      GlobalKey<FormState> titleKey,
      TextEditingController title,
      ValueNotifier<int?> from,
      ValueNotifier<int?> to,
      TextEditingController includedController,
      ValueNotifier<List<String>> excludedKeywords,
      ValueNotifier<List<String>> includedKeywords,
      TextEditingController excludedController,
      ValueNotifier<bool> hideSensitive,
      ValueNotifier<bool> includeThumbnail,
      ValueNotifier<Set<String>> postedBy,
      ValueNotifier<int> articleMinimumWords,
      ValueNotifier<bool> articleHasMedia,
      ValueNotifier<VideoSourceTypes> videoSource,
      ValueNotifier<CurationTypes> curationType,
      ValueNotifier<int> curationMinimumItem) {
    return ScrollShadow(
      color: Theme.of(context).scaffoldBackgroundColor,
      size: 4,
      child: ListView(
        controller: controller,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
        ),
        children: [
          Form(
            key: titleKey,
            child: TextFormField(
              controller: title,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.entitleFilter,
              ),
              validator: RequiredValidator(
                errorText: context.t.fieldRequired,
              ).call,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _fromTo(context, from, to),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _includeWords(
              includedController, context, excludedKeywords, includedKeywords),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (includedKeywords.value.isNotEmpty) ...[
            WordsWrap(
              keywords: includedKeywords.value,
              onDelete: (keyword) {
                includedKeywords.value = List.from(includedKeywords.value)
                  ..remove(keyword);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          _excludeWords(
              excludedController, context, includedKeywords, excludedKeywords),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (excludedKeywords.value.isNotEmpty) ...[
            WordsWrap(
              keywords: excludedKeywords.value,
              onDelete: (keyword) {
                excludedKeywords.value = List.from(excludedKeywords.value)
                  ..remove(keyword);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          Container(
            decoration: defaultBoxDecoration(
              ctx: context,
              radius: kDefaultPadding / 1.5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 3,
            ),
            child: ToggleBox(
              title: context.t.hideSensitiveContent,
              isToggled: hideSensitive.value,
              onToggle: (p0) => hideSensitive.value = p0,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Container(
            decoration: defaultBoxDecoration(
              ctx: context,
              radius: kDefaultPadding / 1.5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 3,
            ),
            child: ToggleBox(
              title: context.t.mustIncludeThumbnail,
              isToggled: includeThumbnail.value,
              onToggle: (p0) => includeThumbnail.value = p0,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _postedBy(context, postedBy),
          if (postedBy.value.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding / 4,
            ),
            _usersList(postedBy),
          ],
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding * 1.5,
          ),
          Text(
            context.t.forArticles.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          FilterSliderBox(
            title: context.t.articleMinWords,
            max: defaultMaxMinumumWordsPerArticle,
            min: 0,
            val: articleMinimumWords.value.toDouble(),
            onChanged: (p0) => articleMinimumWords.value = p0.toInt(),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Container(
            decoration: defaultBoxDecoration(
              ctx: context,
              radius: kDefaultPadding / 1.5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 3,
            ),
            child: ToggleBox(
              title: context.t.showOnlyArticleMedia,
              isToggled: articleHasMedia.value,
              onToggle: (p0) => articleHasMedia.value = p0,
            ),
          ),
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding * 1.5,
          ),
          Text(
            context.t.forVideos.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _videoSourceTypes(context, videoSource),
          const Divider(
            thickness: 0.5,
            height: kDefaultPadding * 1.5,
          ),
          Text(
            context.t.forCurations.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          _curationTypes(context, curationType),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          FilterSliderBox(
            title: context.t.minItemCount,
            max: defaultMaxMinimumItemsPerCuration,
            min: 0,
            val: curationMinimumItem.value.toDouble(),
            onChanged: (p0) => curationMinimumItem.value = p0.toInt(),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }

  Row _curationTypes(
      BuildContext context, ValueNotifier<CurationTypes> curationType) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.curationType.capitalizeFirst(),
          ),
        ),
        Flexible(
          child: CustomDropDown(
            list: CurationTypes.values
                .map(
                  (e) => e.name,
                )
                .toList(),
            capitalize: true,
            defaultValue: curationType.value.name,
            onChanged: (p0) {
              curationType.value = CurationTypes.values.firstWhere(
                (element) => element.name == p0,
                orElse: () => CurationTypes.all,
              );
            },
          ),
        ),
      ],
    );
  }

  Row _videoSourceTypes(
      BuildContext context, ValueNotifier<VideoSourceTypes> videoSource) {
    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.source.capitalizeFirst(),
          ),
        ),
        Flexible(
          child: CustomDropDown(
            list: VideoSourceTypes.values
                .map(
                  (e) => e.name,
                )
                .toList(),
            capitalize: true,
            defaultValue: videoSource.value.name,
            onChanged: (p0) {
              videoSource.value = VideoSourceTypes.values.firstWhere(
                (element) => element.name == p0,
                orElse: () => VideoSourceTypes.all,
              );
            },
          ),
        ),
      ],
    );
  }

  SizedBox _usersList(ValueNotifier<Set<String>> postedBy) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(
          width: kDefaultPadding / 4,
        ),
        itemBuilder: (context, index) {
          final pubkey = postedBy.value.toList()[index];

          return MetadataProvider(
            pubkey: pubkey,
            child: (metadata, nip05) => RemovableProfile(
              metadata: metadata,
              pubkey: pubkey,
              postedBy: postedBy,
            ),
          );
        },
        itemCount: postedBy.value.length,
      ),
    );
  }

  GestureDetector _postedBy(
      BuildContext context, ValueNotifier<Set<String>> postedBy) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return UserToZap(
              onUserSelected: (user) {
                postedBy.value.add(user.pubkey);
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
      child: TextFormField(
        enabled: false,
        decoration: InputDecoration(
          hintText: context.t.postedBy,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
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
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(kDefaultPadding / 1.5),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _excludeWords(
      TextEditingController excludedController,
      BuildContext context,
      ValueNotifier<List<String>> includedKeywords,
      ValueNotifier<List<String>> excludedKeywords) {
    return TextFormField(
      controller: excludedController,
      style: Theme.of(context).textTheme.bodyMedium,
      onFieldSubmitted: (text) {
        if (text.isEmpty) {
          BotToastUtils.showError(context.t.addWord);
          return;
        }

        if (includedKeywords.value.contains(text)) {
          BotToastUtils.showError(
            context.t.wordNotInIncluded,
          );

          return;
        }

        excludedKeywords.value = List.from(excludedKeywords.value)
          ..add(text.trim().toLowerCase());
        excludedController.clear();
      },
      decoration: InputDecoration(
        hintText: context.t.excludedWords,
        suffixIcon: CustomIconButton(
          onClicked: () {
            final text = excludedController.text.trim().toLowerCase();

            if (text.isEmpty) {
              BotToastUtils.showError(context.t.addWord);
              return;
            }

            if (includedKeywords.value.contains(text)) {
              BotToastUtils.showError(
                context.t.wordNotInIncluded,
              );

              return;
            }

            excludedKeywords.value = List.from(excludedKeywords.value)
              ..add(text.trim().toLowerCase());
            excludedController.clear();
          },
          icon: FeatureIcons.addRaw,
          size: 18,
          backgroundColor: kTransparent,
        ),
      ),
    );
  }

  TextFormField _includeWords(
      TextEditingController includedController,
      BuildContext context,
      ValueNotifier<List<String>> excludedKeywords,
      ValueNotifier<List<String>> includedKeywords) {
    return TextFormField(
      controller: includedController,
      style: Theme.of(context).textTheme.bodyMedium,
      onFieldSubmitted: (text) {
        if (text.isEmpty) {
          BotToastUtils.showError(context.t.addWord);
          return;
        }

        if (excludedKeywords.value.contains(text)) {
          BotToastUtils.showError(
            context.t.wordNotInExcluded,
          );

          return;
        }

        includedKeywords.value = List.from(includedKeywords.value)
          ..add(text.trim().toLowerCase());
        includedController.clear();
      },
      decoration: InputDecoration(
        hintText: context.t.includedWords,
        suffixIcon: CustomIconButton(
          onClicked: () {
            final text = includedController.text;

            if (text.isEmpty) {
              BotToastUtils.showError(context.t.addWord);
              return;
            }

            if (excludedKeywords.value.contains(text)) {
              BotToastUtils.showError(
                context.t.wordNotInExcluded,
              );

              return;
            }

            includedKeywords.value = List.from(includedKeywords.value)
              ..add(text.trim().toLowerCase());
            includedController.clear();
          },
          icon: FeatureIcons.addRaw,
          size: 18,
          backgroundColor: kTransparent,
        ),
      ),
    );
  }

  Row _fromTo(
      BuildContext context, ValueNotifier<int?> from, ValueNotifier<int?> to) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: FilterDatePicker(
            text: context.t.from,
            currentDate: from,
            setDate: (date) {
              if (date != null && to.value != null && to.value! <= date) {
                BotToastUtils.showError(
                  context.t.fromDateMessage,
                );
                return;
              }

              from.value = date;
            },
          ),
        ),
        Expanded(
          child: FilterDatePicker(
            text: context.t.to,
            currentDate: to,
            setDate: (date) {
              if (date != null && to.value != null && to.value! >= date) {
                BotToastUtils.showError(
                  context.t.toDateMessage,
                );
                return;
              }

              to.value = date;
            },
          ),
        ),
      ],
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _appBar() {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final listAvailable = state.discoverFilters.isNotEmpty;

        return ModalBottomSheetAppbar(
          title: context.t.addFilter.capitalizeFirst(),
          isBack: listAvailable,
          onClicked: () {
            YNavigator.pop(context);
            if (listAvailable) {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return const AppFilterList(
                    viewType: ViewDataTypes.articles,
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          },
        );
      },
    );
  }
}

class FilterDatePicker extends HookWidget {
  const FilterDatePicker({
    super.key,
    required this.currentDate,
    required this.setDate,
    required this.text,
  });

  final ValueNotifier<int?> currentDate;
  final Function(int?) setDate;
  final String text;

  @override
  Widget build(BuildContext context) {
    final selectedDate = currentDate.value != null
        ? DateTime.fromMillisecondsSinceEpoch(currentDate.value! * 1000)
        : null;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding,
              ),
              child: PickDateTimeWidget(
                focusedDate: selectedDate ?? DateTime.now(),
                isAfter: false,
                onDateSelected: (selectedDate) {
                  setDate(selectedDate.toSecondsSinceEpoch());
                },
                onClearDate: () {
                  setDate(null);
                },
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 3,
          horizontal: kDefaultPadding / 2,
        ),
        decoration: defaultBoxDecoration(
          ctx: context,
          radius: kDefaultPadding / 1.5,
        ),
        child: Row(
          children: [
            _selectedDate(context, selectedDate),
            SvgPicture.asset(
              FeatureIcons.calendar,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            )
          ],
        ),
      ),
    );
  }

  Expanded _selectedDate(BuildContext context, DateTime? selectedDate) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: kDefaultPadding / 8,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
          ),
          Text(
            selectedDate == null
                ? context.t.selectAdate
                : dateFormat4.format(selectedDate),
            style: Theme.of(context).textTheme.labelMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AddNotesFilter extends HookWidget {
  const AddNotesFilter({super.key, required this.notesFilter});

  final NotesFilter notesFilter;

  @override
  Widget build(BuildContext context) {
    final title = useTextEditingController(text: notesFilter.title);
    final includedKeywords = useState(notesFilter.includedKeywords);
    final excludedKeywords = useState(notesFilter.excludedKeywords);
    final includedController = useTextEditingController();
    final excludedController = useTextEditingController();
    final postedBy = useState(notesFilter.postedBy.toSet());
    final hasMedia = useState(notesFilter.onlyMedia);
    final from = useState(notesFilter.from);
    final to = useState(notesFilter.to);
    final isLoading = useState(false);

    final titleKey = useMemoized(
      () => GlobalKey<FormState>(),
    );

    final setFilter = useCallback(
      () async {
        if (titleKey.currentState!.validate()) {
          final nf = NotesFilter(
            onlyMedia: hasMedia.value,
            id: notesFilter.isDefault() ? uuid.v4() : notesFilter.id,
            title: title.text,
            includedKeywords: includedKeywords.value,
            excludedKeywords: excludedKeywords.value,
            postedBy: postedBy.value.toList(),
            from: from.value,
            to: to.value,
          );

          isLoading.value = true;

          if (notesFilter.isDefault()) {
            await appSettingsManagerCubit.addNotesFilter(filter: nf);
          } else {
            await appSettingsManagerCubit.updateNotesFilter(filter: nf);
          }

          isLoading.value = false;

          YNavigator.pop(context);
        }
      },
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Column(
              children: [
                _appbar(),
                Expanded(
                  child: _content(
                      context,
                      controller,
                      titleKey,
                      title,
                      from,
                      to,
                      includedController,
                      excludedKeywords,
                      includedKeywords,
                      excludedController,
                      hasMedia,
                      postedBy),
                ),
                Container(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom / 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: RegularLoadingButton(
                          title: notesFilter.isDefault()
                              ? context.t.add.capitalizeFirst()
                              : context.t.update.capitalizeFirst(),
                          isLoading: isLoading.value,
                          onClicked: setFilter,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ScrollShadow _content(
      BuildContext context,
      ScrollController controller,
      GlobalKey<FormState> titleKey,
      TextEditingController title,
      ValueNotifier<int?> from,
      ValueNotifier<int?> to,
      TextEditingController includedController,
      ValueNotifier<List<String>> excludedKeywords,
      ValueNotifier<List<String>> includedKeywords,
      TextEditingController excludedController,
      ValueNotifier<bool> hasMedia,
      ValueNotifier<Set<String>> postedBy) {
    return ScrollShadow(
      color: Theme.of(context).scaffoldBackgroundColor,
      size: 4,
      child: ListView(
        controller: controller,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
        ),
        children: [
          Form(
            key: titleKey,
            child: TextFormField(
              controller: title,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.entitleFilter,
              ),
              validator: RequiredValidator(
                errorText: context.t.fieldRequired,
              ).call,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _fromTo(context, from, to),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _includeTextfield(
              includedController, context, excludedKeywords, includedKeywords),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (includedKeywords.value.isNotEmpty) ...[
            WordsWrap(
              keywords: includedKeywords.value,
              onDelete: (keyword) {
                includedKeywords.value = List.from(includedKeywords.value)
                  ..remove(keyword);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          _excludeTextfield(
              excludedController, context, includedKeywords, excludedKeywords),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (excludedKeywords.value.isNotEmpty) ...[
            WordsWrap(
              keywords: excludedKeywords.value,
              onDelete: (keyword) {
                excludedKeywords.value = List.from(excludedKeywords.value)
                  ..remove(keyword);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          Container(
            decoration: defaultBoxDecoration(
              ctx: context,
              radius: kDefaultPadding / 1.5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 3,
            ),
            child: ToggleBox(
              title: context.t.showOnlyNotesMedia,
              isToggled: hasMedia.value,
              onToggle: (p0) => hasMedia.value = p0,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _postedBy(context, postedBy),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (postedBy.value.isNotEmpty) ...[
            _usersList(postedBy),
          ],
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }

  SizedBox _usersList(ValueNotifier<Set<String>> postedBy) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(
          width: kDefaultPadding / 4,
        ),
        itemBuilder: (context, index) {
          final pubkey = postedBy.value.toList()[index];

          return MetadataProvider(
            pubkey: pubkey,
            child: (metadata, nip05) => RemovableProfile(
              metadata: metadata,
              pubkey: pubkey,
              postedBy: postedBy,
            ),
          );
        },
        itemCount: postedBy.value.length,
      ),
    );
  }

  GestureDetector _postedBy(
      BuildContext context, ValueNotifier<Set<String>> postedBy) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return UserToZap(
              onUserSelected: (user) {
                postedBy.value.add(user.pubkey);
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
      child: TextFormField(
        enabled: false,
        decoration: InputDecoration(
          hintText: context.t.postedBy,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
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
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(kDefaultPadding / 1.5),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _excludeTextfield(
      TextEditingController excludedController,
      BuildContext context,
      ValueNotifier<List<String>> includedKeywords,
      ValueNotifier<List<String>> excludedKeywords) {
    return TextFormField(
      controller: excludedController,
      style: Theme.of(context).textTheme.bodyMedium,
      onFieldSubmitted: (text) {
        if (text.isEmpty) {
          BotToastUtils.showError(context.t.addWord);
          return;
        }

        if (includedKeywords.value.contains(text)) {
          BotToastUtils.showError(
            context.t.wordNotInIncluded,
          );

          return;
        }

        excludedKeywords.value = List.from(excludedKeywords.value)
          ..add(text.trim().toLowerCase());
        excludedController.clear();
      },
      decoration: InputDecoration(
        hintText: context.t.excludedWords,
        suffixIcon: CustomIconButton(
          onClicked: () {
            final text = excludedController.text.trim().toLowerCase();
            if (text.isEmpty) {
              BotToastUtils.showError(context.t.addWord);
              return;
            }

            if (includedKeywords.value.contains(text)) {
              BotToastUtils.showError(
                context.t.wordNotInIncluded,
              );

              return;
            }

            excludedKeywords.value = List.from(excludedKeywords.value)
              ..add(text.trim().toLowerCase());
            excludedController.clear();
          },
          icon: FeatureIcons.addRaw,
          size: 18,
          backgroundColor: kTransparent,
        ),
      ),
    );
  }

  TextFormField _includeTextfield(
      TextEditingController includedController,
      BuildContext context,
      ValueNotifier<List<String>> excludedKeywords,
      ValueNotifier<List<String>> includedKeywords) {
    return TextFormField(
      controller: includedController,
      style: Theme.of(context).textTheme.bodyMedium,
      onFieldSubmitted: (text) {
        if (text.isEmpty) {
          BotToastUtils.showError(context.t.addWord);
          return;
        }

        if (excludedKeywords.value.contains(text)) {
          BotToastUtils.showError(
            context.t.wordNotInExcluded,
          );

          return;
        }

        includedKeywords.value = List.from(includedKeywords.value)
          ..add(text.trim().toLowerCase());
        includedController.clear();
      },
      decoration: InputDecoration(
        hintText: context.t.includedWords,
        suffixIcon: CustomIconButton(
          onClicked: () {
            final text = includedController.text;
            if (text.isEmpty) {
              BotToastUtils.showError(context.t.addWord);
              return;
            }

            if (excludedKeywords.value.contains(text)) {
              BotToastUtils.showError(
                context.t.wordNotInExcluded,
              );

              return;
            }

            includedKeywords.value = List.from(includedKeywords.value)
              ..add(text.trim().toLowerCase());
            includedController.clear();
          },
          icon: FeatureIcons.addRaw,
          size: 18,
          backgroundColor: kTransparent,
        ),
      ),
    );
  }

  Row _fromTo(
      BuildContext context, ValueNotifier<int?> from, ValueNotifier<int?> to) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: FilterDatePicker(
            text: context.t.from,
            currentDate: from,
            setDate: (date) {
              if (date != null && to.value != null && to.value! <= date) {
                BotToastUtils.showError(
                  context.t.fromDateMessage,
                );
                return;
              }

              from.value = date;
            },
          ),
        ),
        Expanded(
          child: FilterDatePicker(
            text: context.t.to,
            currentDate: to,
            setDate: (date) {
              if (date != null && from.value != null && from.value! >= date) {
                BotToastUtils.showError(
                  context.t.toDateMessage,
                );
                return;
              }

              to.value = date;
            },
          ),
        ),
      ],
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _appbar() {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final listAvailable = state.notesFilters.isNotEmpty;

        return ModalBottomSheetAppbar(
          title: context.t.addFilter.capitalizeFirst(),
          isBack: listAvailable,
          onClicked: () {
            YNavigator.pop(context);
            if (listAvailable) {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return const AppFilterList(
                    viewType: ViewDataTypes.notes,
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          },
        );
      },
    );
  }
}

class AddMediaFilter extends HookWidget {
  const AddMediaFilter({super.key, required this.mediaFilter});

  final MediaFilter mediaFilter;

  @override
  Widget build(BuildContext context) {
    final title = useTextEditingController(text: mediaFilter.title);
    final includedKeywords = useState(mediaFilter.includedKeywords);
    final excludedKeywords = useState(mediaFilter.excludedKeywords);
    final hideSensitive = useState(mediaFilter.hideSensitive);
    final includedController = useTextEditingController();
    final excludedController = useTextEditingController();
    final postedBy = useState(mediaFilter.postedBy.toSet());
    final from = useState(mediaFilter.from);
    final to = useState(mediaFilter.to);
    final isLoading = useState(false);

    final titleKey = useMemoized(
      () => GlobalKey<FormState>(),
    );

    final setFilter = useCallback(
      () async {
        if (titleKey.currentState!.validate()) {
          final mf = MediaFilter(
            id: mediaFilter.isDefault() ? uuid.v4() : mediaFilter.id,
            title: title.text,
            includedKeywords: includedKeywords.value,
            hideSensitive: hideSensitive.value,
            excludedKeywords: excludedKeywords.value,
            postedBy: postedBy.value.toList(),
            from: from.value,
            to: to.value,
          );

          isLoading.value = true;

          if (mediaFilter.isDefault()) {
            await appSettingsManagerCubit.addMediaFilter(filter: mf);
          } else {
            await appSettingsManagerCubit.updateMediaFilter(filter: mf);
          }

          isLoading.value = false;

          YNavigator.pop(context);
        }
      },
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.60,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            child: Column(
              children: [
                _appbar(),
                Expanded(
                  child: _content(
                    context,
                    controller,
                    titleKey,
                    title,
                    from,
                    to,
                    includedController,
                    excludedKeywords,
                    includedKeywords,
                    excludedController,
                    hideSensitive,
                    postedBy,
                  ),
                ),
                Container(
                  height: kBottomNavigationBarHeight +
                      MediaQuery.of(context).padding.bottom,
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom / 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: RegularLoadingButton(
                          title: mediaFilter.isDefault()
                              ? context.t.add.capitalizeFirst()
                              : context.t.update.capitalizeFirst(),
                          isLoading: isLoading.value,
                          onClicked: setFilter,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ScrollShadow _content(
      BuildContext context,
      ScrollController controller,
      GlobalKey<FormState> titleKey,
      TextEditingController title,
      ValueNotifier<int?> from,
      ValueNotifier<int?> to,
      TextEditingController includedController,
      ValueNotifier<List<String>> excludedKeywords,
      ValueNotifier<List<String>> includedKeywords,
      TextEditingController excludedController,
      ValueNotifier<bool> hideSensitive,
      ValueNotifier<Set<String>> postedBy) {
    return ScrollShadow(
      color: Theme.of(context).scaffoldBackgroundColor,
      size: 4,
      child: ListView(
        controller: controller,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(
          vertical: kDefaultPadding / 2,
        ),
        children: [
          Form(
            key: titleKey,
            child: TextFormField(
              controller: title,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: context.t.entitleFilter,
              ),
              validator: RequiredValidator(
                errorText: context.t.fieldRequired,
              ).call,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _fromTo(context, from, to),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _includeTextfield(
              includedController, context, excludedKeywords, includedKeywords),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (includedKeywords.value.isNotEmpty) ...[
            WordsWrap(
              keywords: includedKeywords.value,
              onDelete: (keyword) {
                includedKeywords.value = List.from(includedKeywords.value)
                  ..remove(keyword);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          _excludeTextfield(
              excludedController, context, includedKeywords, excludedKeywords),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (excludedKeywords.value.isNotEmpty) ...[
            WordsWrap(
              keywords: excludedKeywords.value,
              onDelete: (keyword) {
                excludedKeywords.value = List.from(excludedKeywords.value)
                  ..remove(keyword);
              },
            ),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
          ],
          Container(
            decoration: defaultBoxDecoration(
              ctx: context,
              radius: kDefaultPadding / 1.5,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
              vertical: kDefaultPadding / 3,
            ),
            child: ToggleBox(
              title: context.t.sensitiveContent,
              isToggled: hideSensitive.value,
              onToggle: (p0) => hideSensitive.value = p0,
            ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          _postedBy(context, postedBy),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          if (postedBy.value.isNotEmpty) ...[
            _usersList(postedBy),
          ],
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
        ],
      ),
    );
  }

  SizedBox _usersList(ValueNotifier<Set<String>> postedBy) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (context, index) => const SizedBox(
          width: kDefaultPadding / 4,
        ),
        itemBuilder: (context, index) {
          final pubkey = postedBy.value.toList()[index];

          return MetadataProvider(
            pubkey: pubkey,
            child: (metadata, nip05) => RemovableProfile(
              metadata: metadata,
              pubkey: pubkey,
              postedBy: postedBy,
            ),
          );
        },
        itemCount: postedBy.value.length,
      ),
    );
  }

  GestureDetector _postedBy(
      BuildContext context, ValueNotifier<Set<String>> postedBy) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return UserToZap(
              onUserSelected: (user) {
                postedBy.value.add(user.pubkey);
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
      child: TextFormField(
        enabled: false,
        decoration: InputDecoration(
          hintText: context.t.postedBy,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(kDefaultPadding / 1.5),
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
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(kDefaultPadding / 1.5),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField _excludeTextfield(
      TextEditingController excludedController,
      BuildContext context,
      ValueNotifier<List<String>> includedKeywords,
      ValueNotifier<List<String>> excludedKeywords) {
    return TextFormField(
      controller: excludedController,
      style: Theme.of(context).textTheme.bodyMedium,
      onFieldSubmitted: (text) {
        if (text.isEmpty) {
          BotToastUtils.showError(context.t.addWord);
          return;
        }

        if (includedKeywords.value.contains(text)) {
          BotToastUtils.showError(
            context.t.wordNotInIncluded,
          );

          return;
        }

        excludedKeywords.value = List.from(excludedKeywords.value)
          ..add(text.trim().toLowerCase());
        excludedController.clear();
      },
      decoration: InputDecoration(
        hintText: context.t.excludedWords,
        suffixIcon: CustomIconButton(
          onClicked: () {
            final text = excludedController.text.trim().toLowerCase();
            if (text.isEmpty) {
              BotToastUtils.showError(context.t.addWord);
              return;
            }

            if (includedKeywords.value.contains(text)) {
              BotToastUtils.showError(
                context.t.wordNotInIncluded,
              );

              return;
            }

            excludedKeywords.value = List.from(excludedKeywords.value)
              ..add(text.trim().toLowerCase());
            excludedController.clear();
          },
          icon: FeatureIcons.addRaw,
          size: 18,
          backgroundColor: kTransparent,
        ),
      ),
    );
  }

  TextFormField _includeTextfield(
      TextEditingController includedController,
      BuildContext context,
      ValueNotifier<List<String>> excludedKeywords,
      ValueNotifier<List<String>> includedKeywords) {
    return TextFormField(
      controller: includedController,
      style: Theme.of(context).textTheme.bodyMedium,
      onFieldSubmitted: (text) {
        if (text.isEmpty) {
          BotToastUtils.showError(context.t.addWord);
          return;
        }

        if (excludedKeywords.value.contains(text)) {
          BotToastUtils.showError(
            context.t.wordNotInExcluded,
          );

          return;
        }

        includedKeywords.value = List.from(includedKeywords.value)
          ..add(text.trim().toLowerCase());
        includedController.clear();
      },
      decoration: InputDecoration(
        hintText: context.t.includedWords,
        suffixIcon: CustomIconButton(
          onClicked: () {
            final text = includedController.text;
            if (text.isEmpty) {
              BotToastUtils.showError(context.t.addWord);
              return;
            }

            if (excludedKeywords.value.contains(text)) {
              BotToastUtils.showError(
                context.t.wordNotInExcluded,
              );

              return;
            }

            includedKeywords.value = List.from(includedKeywords.value)
              ..add(text.trim().toLowerCase());
            includedController.clear();
          },
          icon: FeatureIcons.addRaw,
          size: 18,
          backgroundColor: kTransparent,
        ),
      ),
    );
  }

  Row _fromTo(
      BuildContext context, ValueNotifier<int?> from, ValueNotifier<int?> to) {
    return Row(
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: FilterDatePicker(
            text: context.t.from,
            currentDate: from,
            setDate: (date) {
              if (date != null && to.value != null && to.value! <= date) {
                BotToastUtils.showError(
                  context.t.fromDateMessage,
                );
                return;
              }

              from.value = date;
            },
          ),
        ),
        Expanded(
          child: FilterDatePicker(
            text: context.t.to,
            currentDate: to,
            setDate: (date) {
              if (date != null && from.value != null && from.value! >= date) {
                BotToastUtils.showError(
                  context.t.toDateMessage,
                );
                return;
              }

              to.value = date;
            },
          ),
        ),
      ],
    );
  }

  BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState> _appbar() {
    return BlocBuilder<AppSettingsManagerCubit, AppSettingsManagerState>(
      builder: (context, state) {
        final listAvailable = state.notesFilters.isNotEmpty;

        return ModalBottomSheetAppbar(
          title: context.t.addFilter.capitalizeFirst(),
          isBack: listAvailable,
          onClicked: () {
            YNavigator.pop(context);
            if (listAvailable) {
              showModalBottomSheet(
                context: context,
                elevation: 0,
                builder: (_) {
                  return const AppFilterList(
                    viewType: ViewDataTypes.media,
                  );
                },
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              );
            }
          },
        );
      },
    );
  }
}

class RegularLoadingButton extends StatelessWidget {
  const RegularLoadingButton({
    super.key,
    required this.title,
    required this.onClicked,
    required this.isLoading,
  });

  final String title;
  final Function() onClicked;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onClicked,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? const SizedBox(
                height: 21,
                child: SpinKitCircle(
                  color: kWhite,
                  size: 21,
                ),
              )
            : Text(title),
      ),
    );
  }
}

class WordsWrap extends StatelessWidget {
  const WordsWrap({
    super.key,
    required this.keywords,
    required this.onDelete,
  });

  final List<String> keywords;
  final Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: kDefaultPadding / 4,
      spacing: kDefaultPadding / 4,
      children: keywords
          .map(
            (keyword) => Chip(
              visualDensity: const VisualDensity(vertical: -4),
              backgroundColor: Theme.of(context).cardColor,
              label: Text(
                keyword,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      height: 1.5,
                    ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(200),
                side: const BorderSide(
                  color: kTransparent,
                ),
              ),
              onDeleted: () => onDelete.call(keyword),
            ),
          )
          .toList(),
    );
  }
}

class FilterSliderBox extends StatelessWidget {
  const FilterSliderBox({
    super.key,
    required this.title,
    required this.max,
    required this.min,
    required this.onChanged,
    required this.val,
  });

  final String title;
  final double max;
  final double min;
  final Function(double) onChanged;
  final double val;

  @override
  Widget build(BuildContext context) {
    final sliderThemeData = SliderTheme.of(context).copyWith(
      trackHeight: 2.0,
      activeTrackColor: Theme.of(context).primaryColor,
      inactiveTrackColor: Theme.of(context).dividerColor,
      overlayColor: kTransparent,
      thumbColor: Theme.of(context).primaryColor,
      overlayShape: SliderComponentShape.noOverlay,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
        ],
        Row(
          spacing: kDefaultPadding / 4,
          children: [
            Expanded(
              child: SliderTheme(
                data: sliderThemeData,
                child: Slider(
                  value: val,
                  min: min,
                  max: max,
                  onChanged: onChanged,
                ),
              ),
            ),
            _sliderContainer(context),
          ],
        ),
      ],
    );
  }

  Container _sliderContainer(BuildContext context) {
    return Container(
      height: 45,
      width: 45,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        val.toInt().toString(),
        style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).highlightColor,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class RemovableProfile extends StatelessWidget {
  const RemovableProfile({
    super.key,
    required this.metadata,
    required this.pubkey,
    required this.postedBy,
  });

  final Metadata metadata;
  final String pubkey;
  final ValueNotifier<Set<String>> postedBy;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const SizedBox(
          width: 60,
          height: 60,
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: ProfilePicture3(
            size: 50,
            image: metadata.picture,
            pubkey: pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: () {},
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: CustomIconButton(
            onClicked: () {
              postedBy.value = Set.from(postedBy.value)..remove(pubkey);
            },
            icon: FeatureIcons.closeRaw,
            size: 15,
            backgroundColor: Theme.of(context).cardColor,
            vd: -3,
          ),
        ),
      ],
    );
  }
}

class ToggleBox extends StatelessWidget {
  const ToggleBox({
    super.key,
    required this.title,
    required this.isToggled,
    required this.onToggle,
    this.style,
  });

  final String title;
  final bool isToggled;
  final Function(bool) onToggle;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: style ?? Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(
          width: kDefaultPadding / 4,
        ),
        Transform.scale(
          scale: 0.8,
          child: CupertinoSwitch(
            value: isToggled,
            activeTrackColor: Theme.of(context).primaryColor,
            onChanged: onToggle,
          ),
        ),
      ],
    );
  }
}
