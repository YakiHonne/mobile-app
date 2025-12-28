import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../dotted_container.dart';

class VideoDownload extends HookWidget {
  const VideoDownload({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    final progress = useState<double>(0);

    useMemoized(
      () async {
        await videoControllerManagerCubit.downloadVideo(
          url,
          (val) {
            progress.value = val;
          },
        );
      },
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.5,
        ),
      ),
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ModalBottomSheetHandle(),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            context.t.downloadingVideo,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: kDefaultPadding / 2),
          Text(
            url,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
                  color: Theme.of(context).highlightColor,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kDefaultPadding),
          SizedBox(
            height: 100,
            width: 100,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: progress.value == 100
                  ? Lottie.asset(
                      LottieAnimations.success,
                      fit: BoxFit.cover,
                      frameRate: const FrameRate(60),
                      repeat: false,
                    )
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: progress.value / 100,
                            backgroundColor: Theme.of(context).dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${progress.value.toStringAsFixed(0)}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).primaryColor,
                                ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: kDefaultPadding),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: progress.value == 100
                ? SizedBox(
                    key: const ValueKey('ok_button'),
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        YNavigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        context.t.ok.capitalize(),
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  )
                : const SizedBox(
                    key: ValueKey('empty_button'),
                    width: double.infinity,
                  ),
          ),
          const SizedBox(height: kBottomNavigationBarHeight),
        ],
      ),
    );
  }
}
