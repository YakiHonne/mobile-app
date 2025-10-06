import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../utils/utils.dart';
import '../../widgets/dotted_container.dart';

class EulaView extends StatelessWidget {
  const EulaView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      width: double.infinity,
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.60,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const ModalBottomSheetHandle(),
            Expanded(
              child: ListView(
                controller: ModalScrollController.of(context),
                padding: const EdgeInsets.all(kDefaultPadding),
                children: [
                  Text(
                    'End-User License Agreement (EULA) for YakiHonne',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  Text(
                    text,
                    style: Theme.of(context).textTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                  for (int i = 0; i < eulaContent.keys.length; i++)
                    _eulaItem(i, context),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.labelMedium,
                      children: [
                        const TextSpan(
                          text:
                              'For questions or concerns about this EULA, please contact YakiHonne at: ',
                        ),
                        TextSpan(
                          text: 'info@yakihonne.com',
                          style: const TextStyle(
                            color: kMainColor,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => sendEmail(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: kDefaultPadding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SizedBox _eulaItem(int i, BuildContext context) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${i + 1}. ${eulaContent.keys.elementAt(i)}',
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: kDefaultPadding / 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int y = 0;
                    y < eulaContent[eulaContent.keys.elementAt(i)]!.length;
                    y++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: kDefaultPadding / 4),
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.labelMedium,
                        children: [
                          TextSpan(
                              text:
                                  '${y + 1}. ${eulaContent[eulaContent.keys.elementAt(i)]!.keys.elementAt(y)}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              )),
                          TextSpan(
                            text: eulaContent[eulaContent.keys.elementAt(i)]!
                                .values
                                .elementAt(y),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(
            height: kDefaultPadding,
          ),
        ],
      ),
    );
  }
}

Future<void> sendEmail() async {
  final Uri params = Uri(
    scheme: 'mailto',
    path: 'info@yakihonne.com',
  );

  await launchUrl(params);
}

const text =
    'Please read this End-User License Agreement ("EULA") carefully before downloading, installing, or using the YakiHonne. By using the App, you agree to be bound by the terms and conditions of this EULA. If you do not agree to the terms and conditions of this EULA, do not download, install, or use the App.';
