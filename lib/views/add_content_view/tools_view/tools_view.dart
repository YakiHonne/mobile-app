import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../logic/tools_cubit/tools_cubit.dart';
import '../../../models/smart_widgets_components.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../smart_widgets_view/widgets/smart_widget_checker.dart';
import '../../widgets/common_thumbnail.dart';
import '../../widgets/custom_icon_buttons.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/note_container.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({
    super.key,
    required this.onContentAdded,
  });

  final Function(String) onContentAdded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ToolsCubit(),
      child: Material(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
            expand: false,
            maxChildSize: 0.95,
            minChildSize: 0.7,
            initialChildSize: 0.95,
            builder: (context, scrollController) => Column(
              children: [
                _titleContainer(context),
                Expanded(
                  child: ToolList(
                    onContentAdded: onContentAdded,
                    scrollController: scrollController,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container _titleContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        child: Row(
          children: [
            const SizedBox(
              width: 32,
            ),
            Expanded(
              child: Text(
                context.t.tools,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            CustomIconButton(
              onClicked: () {
                Navigator.pop(context);
              },
              icon: FeatureIcons.closeRaw,
              size: 20,
              vd: -2,
              backgroundColor: Theme.of(context).cardColor,
            ),
          ],
        ),
      ),
    );
  }
}

class ToolList extends HookWidget {
  const ToolList({
    super.key,
    required this.onContentAdded,
    required this.scrollController,
  });

  final Function(String) onContentAdded;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final tools = useState<List<SmartWidget>>(<SmartWidget>[]);
    final savedTools = useState<List<SmartWidget>>(<SmartWidget>[]);
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return BlocConsumer<ToolsCubit, ToolsState>(
      listener: (context, state) {
        tools.value = state.tools;
        savedTools.value = state.savedTools;
      },
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(kDefaultPadding / 2),
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 4,
                ),
              ),
              _mySavedToolsList(context, savedTools, state),
              SliverToBoxAdapter(
                child: Text(context.t.availableTools),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              _searchTextfield(searchController, context, tools, state),
              if (state.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: kDefaultPadding),
                    child: SpinKitCircle(
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                )
              else
                tools.value.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: kDefaultPadding,
                          ),
                          child: EmptyList(
                            description:
                                context.t.noToolsAvailable.capitalizeFirst(),
                            icon: FeatureIcons.menu,
                          ),
                        ),
                      )
                    : _tootsItems(isTablet, tools, state),
            ],
          ),
        );
      },
    );
  }

  SliverPadding _tootsItems(
      bool isTablet, ValueNotifier<List<SmartWidget>> tools, ToolsState state) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 2,
      ),
      sliver: isTablet
          ? SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: kDefaultPadding / 4,
              crossAxisSpacing: kDefaultPadding / 4,
              childCount: tools.value.length,
              itemBuilder: (context, index) {
                final tool = tools.value[index];
                final app = state.apps[tool.identifier];

                return ToolContainer(
                  tool: tool,
                  appSmartWidget: state.apps[tool.identifier],
                  onContentAdded: onContentAdded,
                  canBeBookmarked: true,
                  isBookmarked: state.bookmarks.contains(tool.identifier),
                  onBookmarkSet: () {
                    context.read<ToolsCubit>().addBookmark(
                        tool.identifier, app?.pubkey ?? tool.pubkey);
                  },
                );
              },
            )
          : SliverList.separated(
              itemBuilder: (context, index) {
                final tool = tools.value[index];
                final app = state.apps[tool.identifier];

                return ToolContainer(
                  tool: tool,
                  appSmartWidget: state.apps[tool.identifier],
                  onContentAdded: onContentAdded,
                  canBeBookmarked: true,
                  isBookmarked: state.bookmarks.contains(tool.identifier),
                  onBookmarkSet: () {
                    context.read<ToolsCubit>().addBookmark(
                        tool.identifier, app?.pubkey ?? tool.pubkey);
                  },
                );
              },
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 4,
              ),
              itemCount: tools.value.length,
            ),
    );
  }

  SliverToBoxAdapter _searchTextfield(
      TextEditingController searchController,
      BuildContext context,
      ValueNotifier<List<SmartWidget>> tools,
      ToolsState state) {
    return SliverToBoxAdapter(
      child: TextFormField(
        controller: searchController,
        style: Theme.of(context).textTheme.bodyMedium,
        onChanged: (search) {
          if (search.isEmpty) {
            tools.value = state.tools;
          } else {
            tools.value = state.tools
                .where(
                  (tool) =>
                      tool.title.toLowerCase().contains(search.toLowerCase()),
                )
                .toList();
          }
        },
        decoration: InputDecoration(
          hintText: context.t.searchSmartWidgets.capitalizeFirst(),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
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
          prefixIconConstraints: const BoxConstraints(
            maxHeight: 45,
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _mySavedToolsList(BuildContext context,
      ValueNotifier<List<SmartWidget>> savedTools, ToolsState state) {
    return SliverToBoxAdapter(
      child: AnimatedCrossFade(
        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.t.mySavedTools),
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            SizedBox(
              height: 58,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final tool = savedTools.value[index];
                  final app = state.apps[tool.identifier];

                  return SizedBox(
                    width: 80.w,
                    child: ToolContainer(
                      tool: tool,
                      appSmartWidget: state.apps[tool.identifier],
                      onContentAdded: onContentAdded,
                      canBeBookmarked: true,
                      canBeRemoved: true,
                      isBookmarked: state.bookmarks.contains(tool.identifier),
                      onBookmarkSet: () {
                        context.read<ToolsCubit>().addBookmark(
                              tool.identifier,
                              app?.pubkey ?? tool.pubkey,
                            );
                      },
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(
                  width: kDefaultPadding / 4,
                ),
                itemCount: savedTools.value.length,
              ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
          ],
        ),
        secondChild: const SizedBox(
          width: double.infinity,
        ),
        crossFadeState: state.savedTools.isNotEmpty
            ? CrossFadeState.showFirst
            : CrossFadeState.showSecond,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class ToolContainer extends StatelessWidget {
  const ToolContainer({
    super.key,
    required this.tool,
    required this.onContentAdded,
    required this.onBookmarkSet,
    this.appSmartWidget,
    this.canBeBookmarked = false,
    this.isBookmarked = false,
    this.canBeRemoved = false,
  });

  final SmartWidget tool;
  final bool canBeBookmarked;
  final bool isBookmarked;
  final bool canBeRemoved;
  final Function(String) onContentAdded;
  final Function() onBookmarkSet;
  final AppSmartWidget? appSmartWidget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onView(context),
      behavior: HitTestBehavior.translucent,
      child: Container(
        padding: const EdgeInsets.all(kDefaultPadding / 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
          border: Border.all(
            width: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          color: Theme.of(context).cardColor,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            spacing: kDefaultPadding / 2,
            children: [
              CommonThumbnail(
                image: tool.type == SWType.basic ? tool.image : tool.icon,
                placeholder:
                    getRandomPlaceholder(input: tool.icon, isPfp: false),
                width: 45,
                height: 45,
                isRound: true,
                radius: kDefaultPadding / 2,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: kDefaultPadding / 4,
                  children: [
                    Text(
                      tool.title.isEmpty ? context.t.noTitle : tool.title,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: tool.title.isEmpty
                                ? Theme.of(context).highlightColor
                                : Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ProfileInfoHeader(
                      pubkey: appSmartWidget?.pubkey ?? tool.pubkey,
                      createdAt: tool.createdAt,
                      isMinimised: true,
                    ),
                  ],
                ),
              ),
              if (!canBeBookmarked || (isBookmarked && !canBeRemoved))
                TextButton(
                  onPressed: () => onView(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    visualDensity: VisualDensity.comfortable,
                  ),
                  child: Text(
                    context.t.view.capitalizeFirst(),
                  ),
                )
              else if (!isBookmarked)
                TextButton(
                  onPressed: onBookmarkSet,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                  ),
                  child: Text(
                    context.t.add.capitalizeFirst(),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: onBookmarkSet,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.comfortable,
                  ),
                  child: Text(
                    context.t.remove.capitalizeFirst(),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  void onView(BuildContext context) {
    final url = appSmartWidget?.url ?? tool.getAppUrl() ?? '';

    if (url.isNotEmpty) {
      openApp(
        context: context,
        url: url,
        app: appSmartWidget,
        title: tool.title,
        onCustomDataAdded: (data) {
          onContentAdded(data);
          YNavigator.pop(context);
        },
      );
    } else {
      YNavigator.pushPage(
        context,
        (context) => SmartWidgetChecker(
          swm: tool,
          naddr: tool.getNaddr(),
          viewMode: true,
        ),
      );
    }
  }
}
