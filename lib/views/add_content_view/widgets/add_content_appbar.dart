import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/add_content_cubit/add_content_cubit.dart';
import '../../../logic/add_media_cubit/add_media_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_icon_buttons.dart';

class AddContentAppbar extends StatelessWidget {
  const AddContentAppbar({
    super.key,
    required this.actionButtonText,
    required this.isActionButtonEnabled,
    required this.onActionClicked,
    this.extra,
    this.extraRight,
  });

  final String actionButtonText;
  final bool isActionButtonEnabled;
  final Widget? extra;
  final Widget? extraRight;
  final Function() onActionClicked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddContentCubit, AddContentState>(
      builder: (context, state) {
        return Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.only(
            right: kDefaultPadding / 2,
            left: kDefaultPadding / 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomIconButton(
                onClicked: () {
                  YNavigator.pop(context);
                },
                icon: FeatureIcons.closeRaw,
                size: 18,
                vd: -1,
                backgroundColor: Theme.of(context).cardColor,
              ),
              Row(
                children: [
                  if (extra != null) extra!,
                  _actionButton(context),
                  if (extraRight != null) extraRight!,
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  AbsorbPointer _actionButton(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isActionButtonEnabled,
      child: TextButton(
        onPressed: onActionClicked,
        style: TextButton.styleFrom(
          backgroundColor: isActionButtonEnabled
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          actionButtonText,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: isActionButtonEnabled
                    ? kWhite
                    : Theme.of(context).highlightColor,
              ),
        ),
      ),
    );
  }
}

class AddMediaAppbar extends StatelessWidget {
  const AddMediaAppbar({
    super.key,
    required this.actionButtonText,
    required this.isActionButtonEnabled,
    required this.onActionClicked,
    this.extra,
    this.extraRight,
  });

  final String actionButtonText;
  final bool isActionButtonEnabled;
  final Widget? extra;
  final Widget? extraRight;
  final Function() onActionClicked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddMediaCubit, AddMediaState>(
      builder: (context, state) {
        return Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.only(
            right: kDefaultPadding / 2,
            left: kDefaultPadding / 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomIconButton(
                onClicked: () {
                  YNavigator.pop(context);
                },
                icon: FeatureIcons.arrowLeft,
                size: 22,
                backgroundColor: kTransparent,
              ),
              Row(
                children: [
                  if (extra != null) extra!,
                  _actionButton(context),
                  if (extraRight != null) extraRight!,
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  AbsorbPointer _actionButton(BuildContext context) {
    return AbsorbPointer(
      absorbing: !isActionButtonEnabled,
      child: TextButton(
        onPressed: onActionClicked,
        style: TextButton.styleFrom(
          backgroundColor: isActionButtonEnabled
              ? Theme.of(context).primaryColor
              : Theme.of(context).cardColor,
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          actionButtonText,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w600,
                color: isActionButtonEnabled
                    ? kWhite
                    : Theme.of(context).highlightColor,
              ),
        ),
      ),
    );
  }
}
