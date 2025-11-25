import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class ToggleContainer extends StatelessWidget {
  const ToggleContainer({
    super.key,
    required this.string1,
    required this.string2,
    required this.onToggle,
    required this.isFirst,
    required this.width,
  });

  final String string1;
  final String string2;
  final Function() onToggle;
  final bool isFirst;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: width,
        height: 35,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: isFirst ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: width / 2,
                height: 35,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      string1,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isFirst
                                ? kWhite
                                : Theme.of(context).primaryColorDark,
                          ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      string2,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isFirst
                                ? Theme.of(context).primaryColorDark
                                : kWhite,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
