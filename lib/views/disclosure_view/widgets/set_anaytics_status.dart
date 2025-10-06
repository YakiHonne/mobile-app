import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/crashlytics_cubit/crashlytics_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';

class SetAnalyticsStatus extends StatelessWidget {
  const SetAnalyticsStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ModalBottomSheetHandle(),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                context.t.yakihonneImprovements.capitalizeFirst(),
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                context.t.crashlyticsTerms.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.t.yakihonneAnCr.capitalizeFirst(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(
                    width: kDefaultPadding / 4,
                  ),
                  BlocBuilder<CrashlyticsCubit, CrashlyticsState>(
                    builder: (context, state) {
                      return Transform.scale(
                        scale: 0.8,
                        child: CupertinoSwitch(
                          value: state.isCrashlyticsEnabled,
                          onChanged: (isToggled) {
                            context
                                .read<CrashlyticsCubit>()
                                .setCrashlyticsStatus(isToggled);

                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
