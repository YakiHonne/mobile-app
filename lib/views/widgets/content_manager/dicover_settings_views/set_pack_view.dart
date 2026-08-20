import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/utils/static_properties.dart';

import '../../../../models/packs_model.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../search_view/search_view.dart';
import '../../custom_icon_buttons.dart';
import '../../data_providers.dart';
import '../../fluid_scaffold.dart';
import '../../fluid_sheet.dart';
import '../../single_image_selector.dart';
import '../add_discover_filter.dart';
import 'search_pack_users.dart';
import 'set_relay_set.dart';

class SetPackView extends HookWidget {
  const SetPackView({super.key, this.pack, this.viewType});

  final PacksModel? pack;
  final ViewDataTypes? viewType;

  @override
  Widget build(BuildContext context) {
    final pubkeys = useState<Set<String>>(pack?.pubkeys ?? <String>{});
    final title = useState(pack?.title ?? '');
    final description = useState(pack?.description ?? '');
    final image = useState(pack?.image ?? '');
    final isSamePackCreator =
        useState(pack?.pubkey == currentSigner!.getPublicKey());
    final isLoading = useState(false);

    final bottomAppBar = FluidBottomBar(
      child: Row(
        children: [
          Expanded(
            child: RegularLoadingButton(
              isLoading: isLoading.value,
              title: (pack != null
                      ? !isSamePackCreator.value
                          ? context.t.clonePack
                          : context.t.update
                      : context.t.add)
                  .capitalizeFirst(),
              onClicked: () async {
                isLoading.value = true;

                await packsSettingsCubit.setPack(
                  pubkeys: pubkeys.value,
                  title: title.value,
                  kind: pack != null
                      ? pack!.kind
                      : viewType == ViewDataTypes.media
                          ? EventKind.MEDIA_PACKS
                          : EventKind.STARTER_PACKS,
                  description: description.value,
                  image: image.value,
                  identifier: pack?.identifier,
                  isOwner: pack?.pubkey == currentSigner!.getPublicKey(),
                  onSuccess: () {
                    isLoading.value = false;
                    YNavigator.pop(context);
                  },
                );

                isLoading.value = false;
              },
            ),
          ),
        ],
      ),
    );

    return FluidScaffold(
      title: pack != null
          ? pack!.pubkey != currentSigner!.getPublicKey()
              ? context.t.clonePack
              : context.t.updatePack
          : context.t.addPack,
      bottomBar: bottomAppBar,
      // M3 BottomAppBar's default height, since this one sets none.
      bottomBarHeight: 80,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(top: fluidScaffoldTopInset(context)),
            ),
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  void addImage() {
                    showAppModalSheet(
                      context: context,
                      builder: (_) {
                        return SingleImageSelector(
                          onUrlProvided: (url, {imeta}) {
                            YNavigator.pop(context);
                            image.value = url;
                          },
                        );
                      },
                      backgroundColor: kTransparent,
                    );
                  }

                  return ImageSelectorWidget(
                    addImage: addImage,
                    url: image,
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding / 2,
              ),
            ),
            SliverToBoxAdapter(
              child: TextFormField(
                initialValue: pack?.title,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (t) {
                  title.value = t;
                },
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: context.t.title.capitalizeFirst(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.t.fieldRequired;
                  }
                  return null;
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding / 4,
              ),
            ),
            SliverToBoxAdapter(
              child: TextFormField(
                initialValue: pack?.description,
                textCapitalization: TextCapitalization.sentences,
                minLines: 2,
                maxLines: 2,
                onChanged: (t) {
                  description.value = t;
                },
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: context.t.description.capitalizeFirst(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.t.fieldRequired;
                  }
                  return null;
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding,
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t.peopleCount(number: pubkeys.value.length),
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          context.t.peopleCountDesc,
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: Theme.of(context).highlightColor,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  CustomIconButton(
                    onClicked: () {
                      YNavigator.pushPage(
                        context,
                        (_) => SearchPackUsers(
                          pubkeys: pubkeys.value,
                          onPubkeysUpdates: (pKeys) {
                            pubkeys.value = Set<String>.from(pKeys);
                          },
                        ),
                      );
                    },
                    icon: FeatureIcons.addRaw,
                    size: 17,
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                ],
              ),
            ),
            if (pubkeys.value.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: kDefaultPadding / 2,
                ),
              ),
              SliverList.separated(
                itemBuilder: (context, index) {
                  final pubkey = pubkeys.value.toList()[index];

                  return MetadataProvider(
                    pubkey: pubkey,
                    child: (metadata, nip05) => SearchAuthorContainer(
                      key: ValueKey(pubkey),
                      metadata: metadata,
                      youFollow: false,
                      onClick: () => onUserSelected.call(
                        pubkey: metadata.pubkey,
                        context: context,
                        selectedPubkeys: pubkeys,
                      ),
                      hasAction: true,
                      isAdded: pubkeys.value.contains(metadata.pubkey),
                    ),
                  );
                },
                separatorBuilder: (context, index) => const SizedBox(
                  height: kDefaultPadding / 2,
                ),
                itemCount: pubkeys.value.length,
              ),
            ],
            const SliverToBoxAdapter(
              child: SizedBox(
                height: kDefaultPadding,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onUserSelected({
    required String pubkey,
    required BuildContext context,
    required ValueNotifier<Set<String>> selectedPubkeys,
  }) {
    final pKeys = Set<String>.from(selectedPubkeys.value);
    if (pKeys.contains(pubkey)) {
      selectedPubkeys.value = pKeys..remove(pubkey);
    } else {
      selectedPubkeys.value = pKeys..add(pubkey);
    }
  }
}
