import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pulse(
            infinite: true,
            child: SvgPicture.asset(
              LogosIcons.logoMarkPurple,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColorDark,
                BlendMode.srcIn,
              ),
              width: 45,
              height: 45,
            ),
          ),
        ],
      ),
    );
  }
}
