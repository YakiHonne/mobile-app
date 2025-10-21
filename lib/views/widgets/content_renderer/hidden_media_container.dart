import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../leading_view/widgets/leading_customization.dart';
import '../custom_icon_buttons.dart';
import '../dotted_container.dart';

class HiddenMediaContainer extends HookWidget {
  const HiddenMediaContainer({
    super.key,
    required this.hideImageStatus,
    required this.invertColor,
    required this.url,
    this.useBorder = true,
    this.includeMessage = false,
  });

  final ValueNotifier<bool> hideImageStatus;
  final bool invertColor;
  final bool useBorder;
  final bool includeMessage;
  final String url;

  @override
  Widget build(BuildContext context) {
    final opacity = useState(0.0);

    return Positioned.fill(
      child: Stack(
        children: [
          /// Main container with border & background
          Container(
            decoration: _buildBoxDecoration(context),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                /// Image with fade-in animation
                _AnimatedImage(
                  url: url,
                  invertColor: invertColor,
                  onImageLoaded: () {
                    if (context.mounted) {
                      opacity.value = 1.0;
                    }
                  },
                  opacity: opacity.value,
                ),

                _OverlayContent(
                  includeMessage: includeMessage,
                  invertColor: invertColor,
                ),
              ],
            ),
          ),

          /// Top-right settings button
          Positioned(
            right: 0,
            top: 0,
            child: CustomIconButton(
              onClicked: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) {
                    return const HiddenMediaSettings();
                  },
                  isScrollControlled: true,
                  useRootNavigator: true,
                  useSafeArea: true,
                  elevation: 0,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                );
              },
              icon: FeatureIcons.settings,
              size: 18,
              backgroundColor: Colors.transparent,
              vd: -1,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  BoxDecoration _buildBoxDecoration(BuildContext context) {
    return BoxDecoration(
      color: invertColor
          ? Theme.of(context).scaffoldBackgroundColor
          : Theme.of(context).canvasColor,
      border: useBorder
          ? Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            )
          : null,
      borderRadius:
          useBorder ? BorderRadius.circular(kDefaultPadding / 2) : null,
    );
  }
}

/// --- Subwidgets ---

/// Handles loading and fade-in of the network image
class _AnimatedImage extends StatelessWidget {
  const _AnimatedImage({
    required this.url,
    required this.opacity,
    required this.onImageLoaded,
    required this.invertColor,
  });

  final String url;
  final double opacity;
  final VoidCallback onImageLoaded;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: ExtendedImage.network(
        mediaServersCubit.makeSignedUrl(sourceUrl: url),
        fit: BoxFit.cover,
        loadStateChanged: (state) {
          switch (state.extendedImageLoadState) {
            case LoadState.loading:
              return const SizedBox();
            case LoadState.completed:
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => onImageLoaded());
              return ExtendedRawImage(
                image: state.extendedImageInfo?.image,
                fit: BoxFit.cover,
              );
            case LoadState.failed:
              return const Center(
                child: Icon(Icons.broken_image_outlined, size: 28),
              );
          }
        },
      ),
    );
  }
}

/// Displays the eye icon and "click to view" text
class _OverlayContent extends StatelessWidget {
  const _OverlayContent({
    required this.includeMessage,
    required this.invertColor,
  });

  final bool includeMessage;
  final bool invertColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            FeatureIcons.visible,
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColorDark,
              BlendMode.srcIn,
            ),
          ),
          if (includeMessage)
            Text(
              context.t.clickToView,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
            ),
        ],
      ),
    );
  }
}

class HiddenMediaSettings extends StatelessWidget {
  const HiddenMediaSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(kDefaultPadding),
          topRight: Radius.circular(kDefaultPadding),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: kDefaultPadding / 2,
          children: [
            const ModalBottomSheetHandle(),
            SvgPicture.asset(
              FeatureIcons.notVisible,
              width: 50,
              height: 50,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
            ),
            Text(
              context.t.hiddenContent,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            Text(
              context.t.hiddenContentDesc,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Theme.of(context).highlightColor,
                  ),
              textAlign: TextAlign.center,
            ),
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  YNavigator.pop(context);

                  showModalBottomSheet(
                    context: context,
                    elevation: 0,
                    builder: (_) {
                      return const LeadingCustomization();
                    },
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  );
                },
                child: Text(
                  context.t.settings.capitalize(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
