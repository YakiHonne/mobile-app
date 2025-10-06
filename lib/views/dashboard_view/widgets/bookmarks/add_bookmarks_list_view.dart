// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../../../logic/dashboard_cubits/dashboard_bookmarks_cubit/bookmarks_cubit.dart';
import '../../../../models/bookmark_list_model.dart';
import '../../../../utils/utils.dart';
import '../../../widgets/custom_app_bar.dart';

class AddBookmarksListView extends HookWidget {
  AddBookmarksListView({
    super.key,
    required this.bookmarksCubit,
    this.bookmarkListModel,
  }) {
    umamiAnalytics.trackEvent(screenName: 'Add bookmark view');
  }

  static const routeName = '/addBookmarksListView';
  static Route route(RouteSettings settings) {
    final list = settings.arguments! as List;
    final bookmarksCubit = list.first as DashboardBookmarksCubit;

    final bookmarkListModel =
        list.length >= 2 ? (list[1] as BookmarkListModel) : null;

    return CupertinoPageRoute(
      builder: (_) => AddBookmarksListView(
        bookmarksCubit: bookmarksCubit,
        bookmarkListModel: bookmarkListModel,
      ),
    );
  }

  final DashboardBookmarksCubit bookmarksCubit;
  final BookmarkListModel? bookmarkListModel;

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    useMemoized(() {
      if (bookmarkListModel != null) {
        bookmarksCubit.setText(text: bookmarkListModel!.title, isTitle: true);
        bookmarksCubit.setText(
            text: bookmarkListModel!.description, isTitle: false);
      }
    });

    return BlocProvider.value(
      value: bookmarksCubit,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.addBookmarkList.capitalize(),
        ),
        body: BlocBuilder<DashboardBookmarksCubit, DashboardBookmarksState>(
          builder: (context, state) {
            return ListView(
              padding: EdgeInsets.all(isTablet ? 15.w : kDefaultPadding / 2),
              children: [
                const SizedBox(
                  height: kDefaultPadding,
                ),
                Text(
                  context.t.setBookmarkTitleDescription.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(
                  height: kDefaultPadding,
                ),
                TextFormField(
                  initialValue: bookmarkListModel?.title,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (title) {
                    context.read<DashboardBookmarksCubit>().setText(
                          text: title,
                          isTitle: true,
                        );
                  },
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: context.t.title.capitalizeFirst(),
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                TextFormField(
                  initialValue: bookmarkListModel?.description,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (description) {
                    context.read<DashboardBookmarksCubit>().setText(
                          text: description,
                          isTitle: false,
                        );
                  },
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: context.t.descriptionOptional.capitalizeFirst(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(
                  height: kDefaultPadding / 4,
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.read<DashboardBookmarksCubit>().addBookmarkList(
                            context: context,
                            bookmarkListModel: bookmarkListModel,
                            onSuccess: () {
                              Navigator.pop(context);
                            },
                          );
                    },
                    child: Text(
                      bookmarkListModel != null
                          ? context.t.update.capitalizeFirst()
                          : context.t.add.capitalizeFirst(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
