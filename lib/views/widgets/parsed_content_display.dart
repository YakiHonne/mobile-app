import 'package:flutter/material.dart';

import '../../models/flash_news_model.dart';
import '../../utils/utils.dart';
import 'dotted_container.dart';

class ParsedContentDisplay extends StatelessWidget {
  const ParsedContentDisplay({
    super.key,
    required this.content,
    this.baseEventModel,
  });

  final String content;
  final BaseEventModel? baseEventModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
        initialChildSize: 0.95,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const ModalBottomSheetHandle(),
            Text(
              context.t.preview,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(
              height: kDefaultPadding,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                width: double.infinity,
                child: ParsedText(text: _getParsedContent()),
              ),
            ),
            const SizedBox(
              height: kBottomNavigationBarHeight,
            ),
          ],
        ),
      ),
    );
  }

  String _getParsedContent() {
    if (baseEventModel == null) {
      return content;
    }

    return '$content \n${baseEventModel!.getScheme()}';
  }
}
