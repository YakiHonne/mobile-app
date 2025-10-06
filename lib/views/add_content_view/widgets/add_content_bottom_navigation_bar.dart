import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../utils/utils.dart';

class AddContentBottomNavigationBar extends HookWidget {
  const AddContentBottomNavigationBar({
    super.key,
    this.index,
    this.removeExtra = true,
  });

  final int? index;
  final bool removeExtra;

  @override
  Widget build(BuildContext context) {
    final types = [
      AppContentType.note,
      AppContentType.article,
      AppContentType.smartWidget,
      if (!removeExtra) ...[
        AppContentType.video,
        AppContentType.curation,
      ],
    ];

    final tabController = useTabController(
      initialLength: types.length,
      initialIndex: index ?? 0,
    );

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      child: ScrollShadow(
        color: Theme.of(context).cardColor,
        size: 20,
        child: SizedBox(
          height: 50,
          child: TabBar(
            isScrollable: true,
            dividerHeight: 0,
            indicatorColor: kTransparent,
            controller: tabController,
            splashFactory: NoSplash.splashFactory,
            padding:
                const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
            labelPadding: EdgeInsets.zero,
            tabAlignment: TabAlignment.start,
            onTap: (index) {
              context.read<AddContentCubit>().setAppContentType(
                    types[index],
                  );
            },
            tabs: types.map((type) {
              final isSelected = tabController.index == types.indexOf(type);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: kDefaultPadding,
                  vertical: kDefaultPadding / 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).scaffoldBackgroundColor
                      : kTransparent,
                  borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        )
                      : null,
                ),
                child: Text(
                  getType(type),
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String getType(AppContentType type) {
    return type == AppContentType.smartWidget
        ? 'Smart widget'
        : type.name.capitalize();
  }
}
