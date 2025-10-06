import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/points_management_cubit/points_management_cubit.dart';
import '../../../utils/utils.dart';
import '../../points_management_view/widgets/points_login_popup.dart';
import '../../widgets/modal_with_blur.dart';

class PropertyYakiChest extends StatelessWidget {
  const PropertyYakiChest({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PointsManagementCubit, PointsManagementState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: kDefaultPadding / 1.5,
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                FeatureIcons.reward,
                width: 25,
                height: 25,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColorDark,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 1.5,
              ),
              Expanded(
                child: Text(
                  context.t.yakiChest.capitalizeFirst(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(
                width: kDefaultPadding / 2,
              ),
              if (state.userGlobalStats != null)
                Container(
                  decoration: BoxDecoration(
                    color: kMainColor,
                    borderRadius: BorderRadius.circular(kDefaultPadding / 2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: kDefaultPadding / 2,
                    vertical: kDefaultPadding / 3,
                  ),
                  child: Text(
                    context.t.connected.capitalizeFirst(),
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(color: kWhite),
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    showBlurredModal(
                      context: context,
                      view: const PointsLoginPopup(),
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: const VisualDensity(
                      vertical: -4,
                      horizontal: 2,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    context.t.connect.capitalizeFirst(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
