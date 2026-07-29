import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../logic/relay_info_cubit/relay_info_cubit.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../dotted_container.dart';
import '../../empty_list.dart';
import '../../modal_sheet_container.dart';
import 'relay_settings_view.dart';
import 'set_relay_set.dart';

class BrowseRelaySets extends StatelessWidget {
  const BrowseRelaySets({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RelayInfoCubit, RelayInfoState>(
      builder: (context, state) {
        final list = state.userRelaySets.entries.toList();

        return ModalSheetContainer(
          child: DraggableScrollableSheet(
            initialChildSize: 0.95,
            minChildSize: 0.60,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                const Center(child: ModalBottomSheetHandle()),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: EmptyList(
                            title: context.t.relaySetListEmpty,
                            description: context.t.relaySetListEmptyDesc,
                            icon: FeatureIcons.relays,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(kDefaultPadding / 2),
                          controller: scrollController,
                          children: [
                            const SizedBox(
                              height: kDefaultPadding / 2,
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              primary: false,
                              itemBuilder: (context, index) {
                                final relaySet = list[index];

                                return RelaySetContainer(
                                  relaySet: relaySet.value,
                                  isSelected: true,
                                  onDelete: () {
                                    relayInfoCubit
                                        .deleteRelaySet(relaySet.value);
                                  },
                                  onEdit: () {
                                    YNavigator.pushPage(
                                      context,
                                      (context) => SetRelaySet(
                                        relaySet: relaySet.value,
                                      ),
                                    );
                                  },
                                );
                              },
                              itemCount: list.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(
                                height: kDefaultPadding / 4,
                              ),
                            ),
                          ],
                        ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom,
                    left: kDefaultPadding / 2,
                    right: kDefaultPadding / 2,
                  ),
                  child: TextButton(
                    onPressed: () {
                      YNavigator.pushPage(
                        context,
                        (context) => const SetRelaySet(),
                      );
                    },
                    child: Text(
                      context.t.addRelaySet,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
