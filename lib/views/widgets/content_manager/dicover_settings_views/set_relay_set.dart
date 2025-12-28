import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../../models/relays_feed.dart';
import '../../../../routes/navigator.dart';
import '../../../../utils/utils.dart';
import '../../../settings_view/widgets/properties_relay_list.dart';
import '../../../settings_view/widgets/relays_update.dart';
import '../../common_thumbnail.dart';
import '../../custom_app_bar.dart';
import '../../custom_icon_buttons.dart';
import '../../single_image_selector.dart';
import '../add_discover_filter.dart';
import 'relay_settings_view.dart';

class SetRelaySet extends HookWidget {
  const SetRelaySet({super.key, this.relaySet});

  final UserRelaySet? relaySet;

  @override
  Widget build(BuildContext context) {
    final formkey = useMemoized(() => GlobalKey<FormState>());
    final title = useState(relaySet == null ? '' : relaySet!.title);
    final description = useState(relaySet == null ? '' : relaySet!.description);
    final addRelayController = useTextEditingController();
    final image = useState(relaySet == null ? '' : relaySet!.image);
    final connect = useState<RelayConnectivity>(RelayConnectivity.idle);
    final addRelayState = useState('');
    final relaysList = useState(
      relaySet?.relays ?? <String>[],
    );
    final isLoading = useState(false);

    final addRelay = useCallback(() {
      final r = getProperRelayUrl(addRelayState.value);
      relaysList.value = List<String>.from(relaysList.value)..insert(0, r);
      connect.value = RelayConnectivity.idle;
      addRelayController.clear();
    });

    final bottomAppBar = BottomAppBar(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RegularLoadingButton(
        isLoading: isLoading.value,
        title: context.t.save,
        onClicked: () async {
          isLoading.value = true;

          await relayInfoCubit.setRelaySet(
            relays: relaysList.value,
            title: title.value,
            description: description.value,
            image: image.value,
            identifier: relaySet?.identifier,
            onSuccess: () {
              isLoading.value = false;
              YNavigator.pop(context);
            },
          );

          isLoading.value = false;
        },
      ),
    );

    return Scaffold(
      appBar: CustomAppBar(
        title:
            relaySet != null ? context.t.updateRelaySet : context.t.addRelaySet,
      ),
      bottomNavigationBar: bottomAppBar,
      body: ListView(
        padding: const EdgeInsets.all(kDefaultPadding / 2),
        children: [
          Builder(
            builder: (context) {
              void addImage() {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) {
                    return SingleImageSelector(
                      onUrlProvided: (url) {
                        YNavigator.pop(context);
                        image.value = url;
                      },
                    );
                  },
                  backgroundColor: kTransparent,
                  useRootNavigator: true,
                  elevation: 0,
                  useSafeArea: true,
                );
              }

              return _imageThumbnail(
                addImage: addImage,
                context: context,
                url: image,
              );
            },
          ),
          const SizedBox(
            height: kDefaultPadding / 2,
          ),
          TextFormField(
            initialValue: relaySet?.title,
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
          const SizedBox(
            height: kDefaultPadding / 4,
          ),
          TextFormField(
            initialValue: relaySet?.description,
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
          const SizedBox(
            height: kDefaultPadding,
          ),
          _searchAvailableRelays(
            formkey,
            addRelayController,
            connect,
            addRelay,
            addRelayState,
            context,
            relaysList,
          ),
          if (relaysList.value.isNotEmpty) ...[
            const SizedBox(
              height: kDefaultPadding / 2,
            ),
            _relaysList(relaysList),
          ],
        ],
      ),
    );
  }

  Widget _relaysList(
    ValueNotifier<List<String>> relaysList,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      primary: false,
      itemBuilder: (context, index) {
        final url = relaysList.value[index];

        return RelayContainer(
          key: ValueKey(url + index.toString()),
          url: url,
          isSelected: true,
          onDelete: () {
            relaysList.value = List<String>.from(relaysList.value)..remove(url);
          },
        );
      },
      itemCount: relaysList.value.length,
      separatorBuilder: (context, index) => const SizedBox(
        height: kDefaultPadding / 4,
      ),
    );
  }

  Widget _searchAvailableRelays(
    GlobalKey<FormState> formkey,
    TextEditingController addRelayController,
    ValueNotifier<RelayConnectivity> connect,
    Function() addRelay,
    ValueNotifier<String> addRelayState,
    BuildContext context,
    ValueNotifier<List<String>> relaysList,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kDefaultPadding / 4,
      children: [
        Expanded(
          child: RelaySearchTextfield(
            addRelayController: addRelayController,
            connect: connect,
            formkey: formkey,
            addRelay: () => addRelay(),
            addRelayState: addRelayState,
            isAdd: true,
          ),
        ),
        SquareIconButton(
          onClicked: () {
            showModalBottomSheet(
              context: context,
              elevation: 0,
              builder: (_) {
                return AvailableRelaysList(
                  onlineRelays: relaysList.value,
                  excludeContantRelays: false,
                  setRelay: (relay) {
                    relaysList.value = List<String>.from(relaysList.value)
                      ..insert(0, relay);
                  },
                  removeRelay: (relay) {
                    relaysList.value = List<String>.from(relaysList.value)
                      ..remove(relay);
                  },
                );
              },
              isScrollControlled: true,
              useRootNavigator: true,
              useSafeArea: true,
            );
          },
        ),
      ],
    );
  }

  Widget _imageThumbnail({
    required BuildContext context,
    required ValueNotifier<String> url,
    required Function() addImage,
  }) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (url.value.isEmpty) {
              addImage();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(
                  kDefaultPadding / 1.5,
                ),
                border: Border.all(
                  width: 0.5,
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: url.value.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: kDefaultPadding / 4,
                        children: [
                          SvgPicture.asset(
                            FeatureIcons.imageAttachment,
                            width: 25,
                            height: 25,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).primaryColorDark,
                              BlendMode.srcIn,
                            ),
                          ),
                          Text(
                            context.t.uploadImage.capitalizeFirst(),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) => CommonThumbnail(
                        image: url.value,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        isRound: true,
                        radius: kDefaultPadding / 1.5,
                      ),
                    ),
            ),
          ),
        ),
        if (url.value.isNotEmpty)
          Positioned(
            top: kDefaultPadding / 4,
            right: kDefaultPadding / 4,
            child: Row(
              spacing: kDefaultPadding / 4,
              children: [
                CustomIconButton(
                  onClicked: addImage,
                  icon: FeatureIcons.editArticle,
                  size: 20,
                  backgroundColor: Theme.of(context).cardColor,
                ),
                CustomIconButton(
                  onClicked: () => url.value = '',
                  icon: FeatureIcons.trash,
                  size: 20,
                  backgroundColor: kRed,
                  iconColor: kWhite,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
