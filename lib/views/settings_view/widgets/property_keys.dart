// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/properties_cubit/properties_cubit.dart';
import '../../../utils/utils.dart';
import '../settings_view.dart';

class PropertySimpleBox extends StatelessWidget {
  const PropertySimpleBox({
    super.key,
    required this.title,
    required this.icon,
    required this.onClick,
  });

  final String title;
  final String icon;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PropertiesCubit, PropertiesState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: onClick,
          behavior: HitTestBehavior.translucent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 1.5,
            ),
            child: PropertyRow(
              isToggled: false,
              icon: icon,
              title: title,
              isRaw: true,
            ),
          ),
        );
      },
    );
  }
}
