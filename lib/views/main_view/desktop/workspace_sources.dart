import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../repositories/localdatabase_repository.dart' show prefs;
import '../../../utils/theme/glass_settings.dart';
import '../../../utils/utils.dart';
import '../../widgets/fluid_source_filter_row.dart';
import 'workspace_content_source.dart';
import 'workspace_content_view.dart';
import 'workspace_discovery.dart';

/// Owns the selected source and keeps visited source views mounted until the
/// account changes.
class DesktopWorkspaceSources extends HookWidget {
  const DesktopWorkspaceSources({
    super.key,
    required this.account,
    required this.following,
    required this.onSearch,
  });

  final String account;
  final Widget following;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final storageKey = 'desktop_workspace_source_$account';
    final selected = useState(switch (prefs.getString(storageKey)) {
      'following' || 'people' => 1,
      'articles' => 2,
      'videos' => 3,
      _ => 0,
    });
    final visited = useState<Set<int>>({selected.value});
    final labels = [
      context.t.discover.capitalizeFirst(),
      context.t.desktopKnowPeople,
      context.t.articles.capitalizeFirst(),
      context.t.videos.capitalizeFirst(),
    ];
    final icons = [
      LucideIcons.compass,
      LucideIcons.users,
      LucideIcons.newspaper,
      LucideIcons.video,
    ];

    void select(int index) {
      selected.value = index;
      visited.value = {...visited.value, index};
      prefs.setString(
          storageKey,
          [
            'discover',
            'people',
            'articles',
            'videos',
          ][index]);
    }

    return Stack(
      children: [
        Positioned.fill(
          child: IndexedStack(index: selected.value, children: [
            if (visited.value.contains(0))
              DesktopWorkspaceDiscovery(account: account, onSearch: onSearch)
            else
              const SizedBox.shrink(),
            if (visited.value.contains(1))
              following
            else
              const SizedBox.shrink(),
            if (visited.value.contains(2))
              DesktopWorkspaceContent(
                  account: account, source: DesktopContentSource.articles)
            else
              const SizedBox.shrink(),
            if (visited.value.contains(3))
              DesktopWorkspaceContent(
                  account: account, source: DesktopContentSource.videos)
            else
              const SizedBox.shrink(),
          ]),
        ),
        Positioned(
          top: fluidFilterRowTop(context),
          left: kDefaultPadding / 2,
          right: kDefaultPadding / 2,
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              child: GlassMenu(
                settings: GlassSettings.menu(context),
                // The pane's MediaQuery has pane-local dimensions, whereas the
                // glass menu's automatic clamp uses window-global coordinates.
                // Center the menu on its trigger instead of mixing those spaces.
                menuAlignment: GlassMenuAlignment.topCenter,
                menuWidth: constraints.maxWidth.clamp(0.0, 220.0),
                triggerBuilder: (context, toggleMenu) => FluidSourceContainer(
                  child: Tooltip(
                    message: context.t.select,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(kDefaultPadding * 2),
                      onTap: toggleMenu,
                      child: SizedBox(
                        height: kFluidSourceControlHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: kDefaultPadding / 2,
                          ),
                          child: Row(children: [
                            SizedBox(
                              width: 30,
                              child: Icon(icons[selected.value], size: 20),
                            ),
                            Expanded(
                              child: Text(labels[selected.value],
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(
                              width: 30,
                              child: Icon(LucideIcons.chevronDown),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
                items: [
                  for (var i = 0; i < labels.length; i++)
                    GlassMenuItem(
                      title: labels[i],
                      icon: Icon(icons[i]),
                      isSelected: i == selected.value,
                      onTap: () => select(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
