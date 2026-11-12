import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

/// A destination and its existing navigation action.
class DesktopMoreEntry {
  const DesktopMoreEntry({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.group,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final String? group;
}

/// Searchable desktop navigation; the caller owns authorization and routing.
class DesktopMoreDialog extends StatefulWidget {
  const DesktopMoreDialog({
    super.key,
    required this.title,
    required this.searchLabel,
    required this.emptyLabel,
    required this.entries,
  });

  final String title;
  final String searchLabel;
  final String emptyLabel;
  final List<DesktopMoreEntry> entries;

  @override
  State<DesktopMoreDialog> createState() => _DesktopMoreDialogState();
}

class _DesktopMoreDialogState extends State<DesktopMoreDialog> {
  var query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.entries
        .where(
          (entry) =>
              entry.label.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultPadding * 1.5),
        side: BorderSide(color: theme.dividerColor, width: 0.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: kDefaultPadding / 2),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  labelText: widget.searchLabel,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => query = value),
              ),
              const SizedBox(height: kDefaultPadding / 2),
              Flexible(
                child: matches.isEmpty
                    ? Center(child: Text(widget.emptyLabel))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final entry = matches[index];
                          final showGroup = entry.group != null &&
                              (index == 0 ||
                                  matches[index - 1].group != entry.group);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showGroup)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: kDefaultPadding / 2,
                                    top: kDefaultPadding / 1.5,
                                    bottom: kDefaultPadding / 4,
                                  ),
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      entry.group!,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: theme.hintColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      kDefaultPadding / 1.5),
                                ),
                                selectedTileColor: theme.cardColor,
                                leading: Icon(entry.icon,
                                    color: theme.primaryColorDark),
                                title: Text(entry.label,
                                    style: theme.textTheme.labelLarge),
                                selected: entry.selected,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  entry.onPressed();
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
