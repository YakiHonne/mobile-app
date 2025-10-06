import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';

class SignerView extends HookWidget {
  const SignerView({
    super.key,
    required this.isSignPublish,
    required this.onSign,
    required this.onCancel,
    required this.content,
  });

  final bool isSignPublish;
  final Map<String, dynamic> content;
  final Function() onSign;
  final Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final automaticSignIn =
        useState(localDatabaseRepository.getAutomaticSigning());

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
      child: DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.85,
        minChildSize: 0.5,
        initialChildSize: 0.85,
        builder: (context, scrollController) => Column(
          children: [
            const ModalBottomSheetHandle(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                children: [
                  SvgPicture.asset(
                    LogosIcons.logoMarkWhite,
                    width: 50,
                    height: 50,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColorDark,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 2,
                  ),
                  Text(
                    context.t.signEvent,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding / 4,
                  ),
                  Text(
                    context.t.signEventDes,
                    style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: Theme.of(context).highlightColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  _signEventContentContainer(context),
                ],
              ),
            ),
            _automaticSigning(automaticSignIn, context),
            _signButton(context),
          ],
        ),
      ),
    );
  }

  Container _signButton(BuildContext context) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
        bottom: MediaQuery.of(context).padding.bottom / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
                visualDensity: VisualDensity.standard,
              ),
              child: Text(
                context.t.cancel.capitalize(),
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).primaryColorDark,
                    ),
              ),
            ),
          ),
          const SizedBox(
            width: kDefaultPadding / 4,
          ),
          Expanded(
            child: TextButton(
              onPressed: onSign,
              child: Text(
                isSignPublish
                    ? context.t.signPublish.capitalize()
                    : context.t.sign.capitalizeFirst(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector _automaticSigning(
      ValueNotifier<bool> automaticSignIn, BuildContext context) {
    return GestureDetector(
      onTap: () {
        automaticSignIn.value = !automaticSignIn.value;
        localDatabaseRepository.setAutomaticSigning(automaticSignIn.value);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding / 2,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: automaticSignIn.value,
              onChanged: (val) {
                localDatabaseRepository.setAutomaticSigning(val ?? false);
                automaticSignIn.value = val ?? false;
              },
              activeColor: kMainColor,
            ),
            Text(
              context.t.enableAutomaticSigning,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }

  Container _signEventContentContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kDefaultPadding / 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: kMainColor,
          width: 0.5,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '{',
              style: TextStyle(
                fontSize: 18,
                color: kMainColor,
                fontFamily: 'Courier New',
              ),
            ),
            ...content.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(
                  left: kDefaultPadding,
                  top: kDefaultPadding / 4,
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '"${entry.key}"',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Colors.orange[300], // Keys in orange
                              fontFamily: 'Courier New',
                            ),
                      ),
                      TextSpan(
                        text: ': ',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                      ),
                      TextSpan(
                        text: '"${entry.value}"',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: kGreen,
                              fontFamily: 'Courier New',
                            ),
                      ),
                      TextSpan(
                        text: ',',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).highlightColor,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Padding(
              padding: EdgeInsets.only(top: kDefaultPadding / 4),
              child: Text(
                '}',
                style: TextStyle(
                  fontSize: 18,
                  color: kMainColor,
                  fontFamily: 'Courier New',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
