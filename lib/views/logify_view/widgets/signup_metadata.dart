import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../utils/utils.dart';

class SignupMetadata extends HookWidget {
  const SignupMetadata({
    super.key,
    required this.formKey,
  });

  final GlobalKey<FormState> formKey;

  @override
  Widget build(BuildContext context) {
    final c = context.read<LogifyCubit>();

    final nameTextEditingController =
        useTextEditingController(text: c.state.name);
    final components = <Widget>[];

    components.addAll(
      [
        Text(
          context.t.details.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: kDefaultPadding / 4),
        Text(
          context.t.shareGlimps.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(
          height: kDefaultPadding,
        ),
        BlocBuilder<LogifyCubit, LogifyState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  SizedBox(
                    height: constraints.maxWidth * 0.55,
                    width: constraints.maxWidth,
                  ),
                  _addEditCover(constraints, context, state),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        context.read<LogifyCubit>().selectMetadataMedia(true);
                      },
                      child: Container(
                        width: constraints.maxWidth * 0.35,
                        height: constraints.maxWidth * 0.35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: kCardDark,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 3,
                          ),
                          image: const DecorationImage(
                            image: AssetImage(Images.profileAvatar),
                          ),
                        ),
                        foregroundDecoration: state.picture != null
                            ? BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).cardColor,
                                border: Border.all(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  width: 3,
                                ),
                                image: DecorationImage(
                                  image: FileImage(state.picture!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        BlocBuilder<LogifyCubit, LogifyState>(
          builder: (context, state) {
            return Center(
              child: TextButton(
                onPressed: () {
                  context.read<LogifyCubit>().selectMetadataMedia(true);
                },
                style: TextButton.styleFrom(
                  backgroundColor: kTransparent,
                ),
                child: Text(
                  state.picture != null
                      ? context.t.editPicture.capitalizeFirst()
                      : context.t.addPicture.capitalizeFirst(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            );
          },
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
      ],
    );

    components.addAll(
      [
        Form(
          key: formKey,
          child: TextFormField(
            controller: nameTextEditingController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              c.setPersonalInformation(
                text: value,
                isName: true,
              );
            },
            validator: (value) {
              if (StringUtil.isBlank(value)) {
                return context.t.setProperName.capitalizeFirst();
              }

              return null;
            },
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: context.t.yourName.capitalizeFirst(),
            ),
          ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        TextFormField(
          maxLines: 4,
          minLines: 3,
          initialValue: c.state.about,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: (value) {
            c.setPersonalInformation(
              text: value,
              isName: false,
            );
          },
          decoration: InputDecoration(
            hintText: context.t.aboutYou.capitalizeFirst(),
          ),
        ),
      ],
    );

    return ListView(
      padding: const EdgeInsets.all(kDefaultPadding),
      shrinkWrap: true,
      children: components,
    );
  }

  Positioned _addEditCover(
      BoxConstraints constraints, BuildContext context, LogifyState state) {
    return Positioned(
      top: 0,
      child: Stack(
        children: [
          Container(
            width: constraints.maxWidth,
            height: constraints.maxWidth * 0.35,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kDefaultPadding / 1.5),
              color: Theme.of(context).cardColor,
            ),
            foregroundDecoration: state.cover != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      kDefaultPadding / 1.5,
                    ),
                    image: DecorationImage(
                      image: FileImage(state.cover!),
                      fit: BoxFit.cover,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 6,
            top: 2,
            child: TextButton(
              onPressed: () {
                context.read<LogifyCubit>().selectMetadataMedia(false);
              },
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                visualDensity: VisualDensity.comfortable,
              ),
              child: Text(
                state.cover != null
                    ? context.t.editCover.capitalizeFirst()
                    : context.t.addCover.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
