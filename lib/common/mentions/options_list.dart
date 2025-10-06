import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class OptionList extends StatelessWidget {
  const OptionList({
    super.key,
    required this.data,
    required this.onTap,
    required this.suggestionListHeight,
    this.suggestionBuilder,
    this.suggestionListDecoration,
  });

  final Widget Function(Map<String, dynamic>)? suggestionBuilder;

  final List<Map<String, dynamic>> data;

  final Function(Map<String, dynamic>) onTap;

  final double suggestionListHeight;

  final BoxDecoration? suggestionListDecoration;

  @override
  Widget build(BuildContext context) {
    return data.isNotEmpty
        ? Container(
            decoration: suggestionListDecoration ??
                const BoxDecoration(color: Colors.white),
            margin: const EdgeInsets.all(kDefaultPadding / 4),
            constraints: BoxConstraints(
              maxHeight: suggestionListHeight,
            ),
            child: ListView.builder(
              itemCount: data.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    onTap(data[index]);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: suggestionBuilder != null
                      ? suggestionBuilder!(data[index])
                      : Container(
                          color: Colors.blue,
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            data[index]['display'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                );
              },
            ),
          )
        : Container();
  }
}
