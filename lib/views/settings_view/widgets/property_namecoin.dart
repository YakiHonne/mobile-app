import 'package:flutter/material.dart';

import '../../../routes/navigator.dart';
import '../../../utils/utils.dart';
import 'namecoin_settings_view.dart';
import 'property_keys.dart';

class PropertyNamecoin extends StatelessWidget {
  const PropertyNamecoin({super.key});

  @override
  Widget build(BuildContext context) {
    return PropertySimpleBox(
      title: 'Namecoin (.bit)',
      icon: FeatureIcons.nip05,
      onClick: () {
        YNavigator.pushPage(
          context,
          (context) => const NamecoinSettingsView(),
        );
      },
    );
  }
}
