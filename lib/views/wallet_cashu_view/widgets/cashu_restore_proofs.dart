import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import '../../widgets/content_manager/add_discover_filter.dart';
import '../../widgets/dotted_container.dart';

class CashuRestoreProofs extends HookWidget {
  const CashuRestoreProofs({
    super.key,
    required this.mintUrl,
  });

  final String mintUrl;

  @override
  Widget build(BuildContext context) {
    final controllers = List.generate(12, (_) => useTextEditingController());
    final wordsCount = useState(0);

    void updateProgress() {
      int count = 0;
      for (final controller in controllers) {
        if (controller.text.trim().isNotEmpty) {
          count++;
        }
      }
      wordsCount.value = count;
    }

    useEffect(() {
      for (final controller in controllers) {
        controller.addListener(updateProgress);
      }
      return () {
        for (final controller in controllers) {
          controller.removeListener(updateProgress);
        }
      };
    }, []);

    return Material(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(kDefaultPadding),
        topRight: Radius.circular(kDefaultPadding),
      ),
      child: Container(
        width: double.infinity,
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
        child: DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          initialChildSize: 0.9,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Column(
              children: [
                const ModalBottomSheetHandle(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: kDefaultPadding / 2,
                    ),
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: kDefaultPadding),
                      _buildSeedInputGrid(context, controllers, updateProgress),
                    ],
                  ),
                ),
                _buildActionSection(context, wordsCount, controllers),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          context.t.restoreWallet,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          context.t.restoreWalletDesc,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).highlightColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        Text(
          mintUrl,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSeedInputGrid(
    BuildContext context,
    List<TextEditingController> controllers,
    VoidCallback updateProgress,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: kDefaultPadding / 2,
        childAspectRatio: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return TextFormField(
          controller: controllers[index],
          onChanged: (value) {
            if (value.trim().contains(' ')) {
              final words = value.trim().split(RegExp(r'\s+'));
              if (words.length > 1) {
                for (var i = 0; i < words.length; i++) {
                  if (index + i < 12) {
                    controllers[index + i].text = words[i];
                  }
                }
                updateProgress();
              }
            }
          },
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: kDefaultPadding / 3,
                right: kDefaultPadding / 4,
              ),
              child: Text(
                '${index + 1}.',
                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).highlightColor,
                    ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            contentPadding: const EdgeInsets.symmetric(
              vertical: kDefaultPadding / 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    ValueNotifier<int> wordsCount,
    List<TextEditingController> controllers,
  ) {
    return Column(
      children: [
        const SizedBox(height: kDefaultPadding),
        Text(
          context.t.seedPhraseLocallyOnly,
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).primaryColor,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: kDefaultPadding / 2),
        _buildProgressBar(context, wordsCount),
        const SizedBox(height: kDefaultPadding),
        SizedBox(
          width: double.infinity,
          child: RegularLoadingButton(
            title: context.t.restoreWallet,
            onClicked: () async {
              final amount = await cashuWalletManagerCubit.restoreProofs(
                mintUrl: mintUrl,
                mnemonic: controllers.map((e) => e.text).join(' '),
              );

              if (amount >= 0 && context.mounted) {
                YNavigator.pop(context);
              }
            },
            isLoading: false,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }

  Widget _buildProgressBar(
      BuildContext context, ValueNotifier<int> wordsCount) {
    return Row(
      children: [
        Text(
          '${wordsCount.value} / 12',
          style: Theme.of(context).textTheme.labelLarge!.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: kDefaultPadding / 2),
        Expanded(
          child: LinearProgressIndicator(
            value: wordsCount.value / 12,
            backgroundColor: Theme.of(context).dividerColor,
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}
