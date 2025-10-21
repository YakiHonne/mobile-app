import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../models/app_models/diverse_functions.dart';
import '../../routes/navigator.dart';
import '../../routes/pages_router.dart';
import '../../utils/utils.dart';
import '../logify_view/logify_view.dart';

class HorizontalViewModeWidget extends StatelessWidget {
  const HorizontalViewModeWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          ExtendedImage.asset(
            PagesIcons.notConnected,
            width: 12.w,
            height: 12.w,
            compressionRatio: 1,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _usingViewMode(context),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _login(context),
        ],
      ),
    );
  }

  TextButton _login(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
      onPressed: () {
        YNavigator.push(
          context,
          OpacityAnimationPageRoute(
            builder: (context) => LogifyView(),
            settings: const RouteSettings(),
          ),
        );
      },
      child: Text(
        context.t.login.capitalizeFirst(),
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontWeight: FontWeight.w600, height: 1),
      ),
    );
  }

  Expanded _usingViewMode(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.usingViewMode.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            context.t.usingViewModeDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }
}

class RelayLoginHorizontalViewModeWidget extends StatelessWidget {
  const RelayLoginHorizontalViewModeWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            FeatureIcons.relaysOrbit,
            width: 12.w,
            height: 12.w,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _notConnected(context),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _login(context),
        ],
      ),
    );
  }

  TextButton _login(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
      onPressed: () {
        YNavigator.push(
          context,
          OpacityAnimationPageRoute(
            builder: (context) => LogifyView(),
            settings: const RouteSettings(),
          ),
        );
      },
      child: Text(
        context.t.login.capitalizeFirst(),
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontWeight: FontWeight.w600, height: 1),
      ),
    );
  }

  Expanded _notConnected(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.youNotConnected.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            context.t.youNotConnectedDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }
}

class VerticalViewModeWidget extends StatelessWidget {
  const VerticalViewModeWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExtendedImage.asset(
          PagesIcons.notConnected,
          width: 20.w,
          height: 20.w,
          compressionRatio: 1,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          context.t.usingViewMode.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Text(
          context.t.usingViewModeDesc.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        _login(context),
      ],
    );
  }

  TextButton _login(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
      onPressed: () {
        YNavigator.push(
          context,
          OpacityAnimationPageRoute(
            builder: (context) => LogifyView(),
            settings: const RouteSettings(),
          ),
        );
      },
      child: Text(
        context.t.login.capitalizeFirst(),
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontWeight: FontWeight.w600, height: 1),
      ),
    );
  }
}

class LoadDmsWidget extends StatelessWidget {
  const LoadDmsWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.t.messagesNotLoaded.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            context.t.messagesNotLoadedDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          TextButton(
            onPressed: () {
              dmsCubit.loadLocalRemoteSignerDms();
            },
            child: Text(
              context.t.loadMessages.capitalizeFirst(),
            ),
          ),
        ],
      ),
    );
  }
}

class NoMessagesWidget extends StatelessWidget {
  const NoMessagesWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.t.messagesDisabled.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          Text(
            context.t.messagesDisabledDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          ExtendedImage.asset(
            PagesIcons.unauthorizedMessages,
            width: 45.w,
            height: 45.w,
            compressionRatio: 1,
          ),
        ],
      ),
    );
  }
}

class MutedUserContent extends StatelessWidget {
  const MutedUserContent({
    super.key,
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExtendedImage.asset(
          PagesIcons.mutedUser,
          width: 20.w,
          height: 20.w,
          compressionRatio: 1,
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        Text(
          context.t.unaccessibleContent.capitalizeFirst(),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 4,
        ),
        Text(
          context.t.mutedUserDesc.capitalizeFirst(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
        const SizedBox(
          height: kDefaultPadding / 2,
        ),
        _unmute(context),
      ],
    );
  }

  TextButton _unmute(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
      onPressed: () {
        doIfCanSign(
          func: () {
            setMuteStatus(
              pubkey: pubkey,
              onSuccess: () {},
            );
          },
          context: context,
        );
      },
      child: Text(
        context.t.unmute.capitalizeFirst(),
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontWeight: FontWeight.w600, height: 1),
      ),
    );
  }
}

class MutedUserActionBox extends StatelessWidget {
  const MutedUserActionBox({
    super.key,
    required this.pubkey,
  });

  final String pubkey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          kDefaultPadding / 2,
        ),
        color: Theme.of(context).cardColor,
      ),
      margin: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
      ),
      child: Row(
        children: [
          ExtendedImage.asset(
            PagesIcons.mutedUser,
            width: 12.w,
            height: 12.w,
            compressionRatio: 1,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _unaccessibleContent(context),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _unmute(context),
        ],
      ),
    );
  }

  TextButton _unmute(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(visualDensity: VisualDensity.comfortable),
      onPressed: () {
        doIfCanSign(
          func: () {
            setMuteStatus(
              pubkey: pubkey,
              onSuccess: () {},
            );
          },
          context: context,
        );
      },
      child: Text(
        context.t.unmute.capitalizeFirst(),
        style: Theme.of(context)
            .textTheme
            .bodySmall!
            .copyWith(fontWeight: FontWeight.w600, height: 1),
      ),
    );
  }

  Expanded _unaccessibleContent(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.unaccessibleContent.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Text(
            context.t.mutedUserDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ),
    );
  }
}

class NoInternetView extends StatelessWidget {
  const NoInternetView({
    super.key,
    required this.onClicked,
    required this.isButtonEnabled,
  });

  final Function() onClicked;
  final bool isButtonEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            PagesIcons.noData,
            width: 35.w,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            context.t.noInternetAccess.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          NoInternetRow(
            title: context.t.checkModelRouter.capitalizeFirst(),
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          NoInternetRow(
            title: context.t.reconnectWifi.capitalizeFirst(),
          ),
          if (isButtonEnabled) ...[
            const SizedBox(
              height: kDefaultPadding,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onClicked,
                  child: Text(
                    context.t.tryAgain.capitalizeFirst(),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}

class NoInternetRow extends StatelessWidget {
  const NoInternetRow({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          ToastsIcons.check,
          colorFilter: const ColorFilter.mode(kDimGrey, BlendMode.srcATop),
          width: 5.w,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class WrongView extends StatelessWidget {
  const WrongView({
    super.key,
    required this.onClicked,
  });

  final Function() onClicked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            PagesIcons.noData,
            width: 35.w,
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            context.t.somethingWentWrong.capitalizeFirst(),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
          Text(
            context.t.somethingWentWrongDesc.capitalizeFirst(),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: kDefaultPadding + 10,
          ),
          TextButton(
            onPressed: onClicked,
            child: Text(context.t.refresh.capitalizeFirst()),
          ),
        ],
      ),
    );
  }
}
