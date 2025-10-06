// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_scroll_shadow/flutter_scroll_shadow.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:open_filex/open_filex.dart';

import '../../../logic/logify_cubit/logify_cubit.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';

class SignupPreview extends StatelessWidget {
  const SignupPreview({
    super.key,
    this.removePadding,
    this.onExport,
  });

  final bool? removePadding;
  final Function()? onExport;

  @override
  Widget build(BuildContext context) {
    final components = <Widget>[];

    components.add(
      BlocBuilder<LogifyCubit, LogifyState>(
        builder: (context, state) {
          return Column(
            children: [
              _thumbnail(state),
              const SizedBox(
                height: kDefaultPadding,
              ),
              Text(
                state.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: kDefaultPadding / 2,
              ),
              if (state.about.isNotEmpty) ...[
                SizedBox(
                  width: 80.w,
                  child: Text(
                    state.about,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ],
            ],
          );
        },
      ),
    );

    components.add(
      const SizedBox(
        height: kDefaultPadding,
      ),
    );

    components.add(
      Container(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(kDefaultPadding / 2),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              FeatureIcons.keys,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(
              width: kDefaultPadding / 2,
            ),
            Expanded(
              child: Text(
                context.read<LogifyCubit>().state.wallet.isEmpty
                    ? context.t.secKeyDesc.capitalizeFirst()
                    : context.t.secKeyWalletDesc.capitalizeFirst(),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );

    components.add(
      const SizedBox(
        height: kDefaultPadding / 2,
      ),
    );

    components.add(
      BlocBuilder<LogifyCubit, LogifyState>(
        builder: (context, state) {
          return TextButton(
            onPressed: onExport ??
                () async {
                  final res = await exportKeysToUserDirectory(
                    publicKey: Keychain.getPublicKey(state.private),
                    secretKey: state.private,
                  );

                  if (res == ResultType.noAppToOpen) {
                    BotToastUtils.showError(context.t.noApp);
                  }
                },
            style: TextButton.styleFrom(
              backgroundColor: kGreen,
            ),
            child: Text(
              onExport != null
                  ? context.t.exportCredentials
                  : context.t.exportKeys,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          );
        },
      ),
    );

    return BlocBuilder<LogifyCubit, LogifyState>(
      builder: (context, state) {
        return ScrollShadow(
          child: ListView(
            shrinkWrap: true,
            padding: removePadding != null
                ? const EdgeInsets.symmetric(vertical: kDefaultPadding)
                : const EdgeInsets.all(kDefaultPadding),
            children: components,
          ),
        );
      },
    );
  }

  LayoutBuilder _thumbnail(LogifyState state) {
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          SizedBox(
            height: constraints.maxWidth * 0.50,
            width: constraints.maxWidth,
          ),
          Container(
            width: constraints.maxWidth,
            height: constraints.maxWidth * 0.30,
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
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: constraints.maxWidth * 0.35,
              height: constraints.maxWidth * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
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
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 3),
                      image: DecorationImage(
                        image: FileImage(state.picture!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget profileInfoRow({
    required BuildContext context,
    required String title,
    required String content,
    required String copyText,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kWhite,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                height: kDefaultPadding / 4,
              ),
              Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: kWhite,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Clipboard.setData(
              ClipboardData(
                text: content,
              ),
            );

            BotToastUtils.showSuccess(copyText);
          },
          style: TextButton.styleFrom(
            backgroundColor: kTransparent,
            visualDensity: const VisualDensity(
              vertical: -4,
              horizontal: -2,
            ),
          ),
          icon: SvgPicture.asset(
            FeatureIcons.copy,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              kWhite,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }
}
