import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/points_management_cubit/points_management_cubit.dart';
import '../../utils/utils.dart';
import '../widgets/profile_picture.dart';
import 'widgets/points_stats_containers.dart';

class PointsStatisticsView extends StatelessWidget {
  PointsStatisticsView({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Points statistics view');
  }
  static const routeName = '/pointsStatisticsView';

  static Route route(RouteSettings settings) {
    return CupertinoPageRoute(
      builder: (_) => PointsStatisticsView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        final isConnected = state.userGlobalStats != null;

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: kToolbarHeight + 80,
                  pinned: true,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  stretch: true,
                  leading: FadeInRight(
                    duration: const Duration(milliseconds: 500),
                    from: 30,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).cardColor,
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    GestureDetector(
                      onTap: () {
                        openWebPage(url: pointsSystemUrl);
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).cardColor,
                        child: const Icon(
                          Icons.info,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: kDefaultPadding / 2,
                    )
                  ],
                  flexibleSpace: _flexibleBar(),
                ),
              ];
            },
            body: isConnected ? const PointsStatContainers() : const SizedBox(),
          ),
        );
      },
    );
  }

  FlexibleSpaceBar _flexibleBar() {
    return FlexibleSpaceBar(
      centerTitle: false,
      background: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ProfilePicture2(
                    size: 120,
                    image: nostrRepository.currentMetadata.picture,
                    pubkey: nostrRepository.currentMetadata.pubkey,
                    padding: 0,
                    strokeWidth: 3,
                    strokeColor: Theme.of(context).scaffoldBackgroundColor,
                    onClicked: () {},
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
