import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../logic/packs_settings_cubit/packs_settings_cubit.dart';
import '../../../../models/app_models/diverse_functions.dart';
import '../../../../models/packs_model.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../explore_packs_view/explore_packs_view.dart';
import '../../empty_list.dart';
import '../../response_snackbar.dart';
import 'set_pack_view.dart';

class PacksSettingsView extends HookWidget {
  const PacksSettingsView(
      {super.key, required this.controller, required this.viewType});

  final ScrollController controller;
  final ViewDataTypes viewType;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PacksSettingsCubit, PacksSettingsState>(
      builder: (context, state) {
        List<PacksModel> filteredPacks = [];
        final packs = state.packs.entries;

        if (viewType == ViewDataTypes.media) {
          filteredPacks = packs
              .where(
                (p) => state.starterPacks[p.key] == false,
              )
              .map((e) => e.value)
              .toList();
        } else {
          filteredPacks = packs
              .where(
                (p) => state.starterPacks[p.key] ?? false,
              )
              .map((e) => e.value)
              .toList();
        }

        return Column(
          children: [
            Expanded(
              child: filteredPacks.isEmpty
                  ? Center(
                      child: EmptyList(
                        title: context.t.noPacksFound,
                        description: context.t.noPacksFoundDesc,
                        icon: FeatureIcons.search,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(kDefaultPadding / 2),
                      separatorBuilder: (context, index) => const SizedBox(
                        height: kDefaultPadding / 2,
                      ),
                      itemCount: filteredPacks.length,
                      itemBuilder: (context, index) {
                        final pack = filteredPacks[index];

                        return PackCard(
                          pack: pack,
                          enableBrowse: false,
                          hasActions: true,
                          onEdit: () {
                            doIfCanSign(
                              func: () {
                                YNavigator.pushPage(
                                  context,
                                  (context) => SetPackView(
                                    viewType: viewType,
                                    pack: pack,
                                  ),
                                );
                              },
                              context: context,
                            );
                          },
                          onDelete: () {
                            doIfCanSign(
                              func: () {
                                showCupertinoDeletionDialogue(
                                  context: context,
                                  title: context.t.deletePack,
                                  description: context.t.deletePackDesc,
                                  buttonText:
                                      context.t.delete.capitalizeFirst(),
                                  onDelete: () async {
                                    await packsSettingsCubit.deletePack(pack);
                                    if (context.mounted) {
                                      YNavigator.pop(context);
                                    }
                                  },
                                );
                              },
                              context: context,
                            );
                          },
                        );
                      },
                    ),
            ),
            _addButton(context),
          ],
        );
      },
    );
  }

  Container _addButton(
    BuildContext context,
  ) {
    return Container(
      height:
          kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
      width: double.infinity,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom / 2,
        left: kDefaultPadding / 2,
        right: kDefaultPadding / 2,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                doIfCanSign(
                  func: () {
                    YNavigator.pushPage(
                      context,
                      (context) => SetPackView(viewType: viewType),
                    );
                  },
                  context: context,
                );
              },
              child: Text(context.t.add.capitalizeFirst()),
            ),
          ),
        ],
      ),
    );
  }
}
