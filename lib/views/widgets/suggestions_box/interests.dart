import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/suggestion_box_cubit/suggestions_box_cubit.dart';
import '../../../models/app_models/diverse_functions.dart';
import '../../../models/topic.dart';
import '../../../utils/utils.dart';
import '../common_thumbnail.dart';
import '../custom_icon_buttons.dart';

class SuggestedInterests extends StatelessWidget {
  const SuggestedInterests({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      key: const PageStorageKey('suggested-interests'),
      initialData: nostrRepository.interests,
      stream: nostrRepository.interestsStream,
      builder: (context, snapshot) {
        return BlocBuilder<SuggestionsBoxCubit, SuggestionsBoxState>(
          builder: (context, state) {
            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              primary: false,
              itemBuilder: (context, index) {
                final interest = state.suggestions[index];

                return SuggestedInterestContainer(
                  interest: interest,
                  isAdded:
                      snapshot.data?.contains(interest.topic.toLowerCase()) ??
                          false,
                );
              },
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 4,
              ),
              itemCount: state.suggestions.length,
            );
          },
        );
      },
    );
  }
}

class SuggestedInterestContainer extends StatelessWidget {
  const SuggestedInterestContainer({
    super.key,
    required this.interest,
    required this.isAdded,
  });

  final Topic interest;
  final bool isAdded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          CommonThumbnail(
            image: interest.icon,
            width: 40,
            height: 40,
            radius: kDefaultPadding / 2,
            isRound: true,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Text(
              interest.topic,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          CustomIconButton(
            onClicked: () {
              doIfCanSign(
                func: () async {
                  suggestionsBoxCubit.setInterest(interest.topic);
                },
                context: context,
              );
            },
            icon: FeatureIcons.addRaw,
            iconColor: kWhite,
            size: 15,
            backgroundColor: Theme.of(context).primaryColor,
            vd: -2,
          ),
        ],
      ),
    );
  }
}
