// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../logic/smart_widget_search_cubit/smart_widget_search_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';

class SmartWidgetSearchContainer extends HookWidget {
  const SmartWidgetSearchContainer({
    super.key,
    required this.searchController,
    required this.isSearchEnabled,
  });

  final TextEditingController searchController;
  final ValueNotifier<bool> isSearchEnabled;

  @override
  Widget build(BuildContext context) {
    final isSendingEnabled = useState(false);
    final onSearch = useCallback(() {
      if (isSearchEnabled.value) {
        context.read<SmartWidgetSearchCubit>().getSmartWidgetThroughDvm(
              searchController.text,
            );

        searchController.clear();
        isSendingEnabled.value = true;
      } else {
        doIfCanSign(
          func: () {
            context.read<SmartWidgetSearchCubit>().sendSmartWidgetChatMessage(
                  search: searchController.text,
                  onDone: () {},
                );
            searchController.clear();
          },
          context: context,
        );
      }
    });

    final child = Container(
      height: 110,
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      margin: const EdgeInsets.symmetric(vertical: kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          _searchTextfield(context, onSearch, isSendingEnabled),
          _searchActions(context, isSendingEnabled, onSearch),
        ],
      ),
    );

    return child;
  }

  Row _searchActions(BuildContext context, ValueNotifier<bool> isSendingEnabled,
      Function() onSearch) {
    return Row(
      children: [
        Expanded(
          child: Row(
            spacing: kDefaultPadding / 4,
            children: [
              SmartWidgetSearchOptionBox(
                icon: FeatureIcons.search,
                isActive: isSearchEnabled.value,
                onClicked: () {
                  isSearchEnabled.value = true;
                },
                title: context.t.widgetSearch.capitalizeFirst(),
              ),
              SmartWidgetSearchOptionBox(
                icon: FeatureIcons.notification,
                isActive: !isSearchEnabled.value,
                onClicked: () {
                  isSearchEnabled.value = false;
                },
                title: context.t.getInspired.capitalizeFirst(),
              ),
            ],
          ),
        ),
        AbsorbPointer(
          absorbing: !isSendingEnabled.value,
          child: CustomIconButton(
            onClicked: () => onSearch(),
            icon: FeatureIcons.send,
            size: 20,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
      ],
    );
  }

  Expanded _searchTextfield(BuildContext context, Function() onSearch,
      ValueNotifier<bool> isSendingEnabled) {
    return Expanded(
      child: TextFormField(
        controller: searchController,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: !isSearchEnabled.value
              ? context.t.askMeSomething.capitalizeFirst()
              : context.t.typeKeywords.capitalizeFirst(),
          contentPadding: EdgeInsets.zero,
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: kTransparent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kTransparent),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kTransparent),
          ),
          disabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kTransparent),
          ),
        ),
        maxLines: 2,
        style: Theme.of(context).textTheme.bodyMedium,
        onFieldSubmitted: (_) => onSearch(),
        onChanged: (search) {
          if (search.trim().isEmpty) {
            isSendingEnabled.value = false;
          } else {
            isSendingEnabled.value = true;
          }
        },
      ),
    );
  }
}

class SmartWidgetSearchOptionBox extends StatelessWidget {
  const SmartWidgetSearchOptionBox({
    super.key,
    required this.isActive,
    required this.title,
    required this.icon,
    required this.onClicked,
    this.includIcon = true,
    this.reverse = false,
  });

  final bool isActive;
  final String title;
  final String icon;
  final bool includIcon;
  final Function() onClicked;
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final active = !reverse
        ? Theme.of(context).scaffoldBackgroundColor
        : Theme.of(context).cardColor;

    final inactive = reverse
        ? Theme.of(context).scaffoldBackgroundColor
        : Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
          vertical: kDefaultPadding / 3,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(300),
          color: isActive ? active : inactive,
          border: Border.all(
            width: 0.5,
            color: Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          spacing: kDefaultPadding / 4,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (includIcon)
              SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
            Flexible(
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SmartWidgetTypeBox extends StatelessWidget {
  const SmartWidgetTypeBox({
    super.key,
    required this.isActive,
    required this.title,
    required this.onClicked,
  });

  final bool isActive;
  final String title;
  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClicked,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding / 2,
                vertical: kDefaultPadding / 4,
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(
                height: 3,
              ),
              secondChild: Container(
                decoration: BoxDecoration(
                  color: kMainColor,
                  borderRadius: BorderRadius.circular(
                    kDefaultPadding / 4,
                  ),
                ),
                height: 3,
                width: 60,
              ),
              crossFadeState: isActive
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
