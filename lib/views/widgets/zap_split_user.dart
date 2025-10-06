// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../utils/utils.dart';
import 'buttons_containers_widgets.dart';
import 'dotted_container.dart';
import 'profile_picture.dart';

class ZapSplitUsers extends HookWidget {
  const ZapSplitUsers({
    super.key,
    required this.currentPubkeys,
    required this.onAddUser,
    required this.onRemoveUser,
  });

  final List<String> currentPubkeys;
  final Function(String) onAddUser;
  final Function(String) onRemoveUser;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    final authors = useState(<Metadata>[]);
    final pubkeysList = useState(currentPubkeys);

    return Container(
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
        initialChildSize: 0.9,
        minChildSize: 0.60,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => CustomScrollView(
          controller: scrollController,
          slivers: [
            const SliverToBoxAdapter(
              child: Center(
                child: ModalBottomSheetHandle(),
              ),
            ),
            _appBar(textEditingController, authors, context),
            const SliverToBoxAdapter(
              child: SizedBox(height: kDefaultPadding / 2),
            ),
            _items(authors, pubkeysList),
            const SliverToBoxAdapter(
              child: SizedBox(height: kDefaultPadding),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _items(ValueNotifier<List<Metadata>> authors,
      ValueNotifier<List<String>> pubkeysList) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      sliver: SliverList.builder(
        itemBuilder: (context, index) {
          final metadata = authors.value[index];

          return ZapSplitUserContainer(
            metadata: metadata,
            isPresent: pubkeysList.value.contains(metadata.pubkey),
            onRemoveUser: onRemoveUser,
            pubkeysList: pubkeysList,
            onAddUser: onAddUser,
          );
        },
        itemCount: authors.value.length,
      ),
    );
  }

  SliverAppBar _appBar(TextEditingController textEditingController,
      ValueNotifier<List<Metadata>> authors, BuildContext context) {
    return SliverAppBar(
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      pinned: true,
      actions: const [
        SizedBox.shrink(),
      ],
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: TextFormField(
          controller: textEditingController,
          onChanged: (search) async {
            if (search.isEmpty) {
              authors.value = [];
            } else {
              authors.value = await metadataCubit.searchCacheMetadatas(search);
            }
          },
          decoration: InputDecoration(
            hintText: context.t.search.capitalizeFirst(),
            prefixIcon: const Icon(
              Icons.search,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                textEditingController.clear();
                authors.value = [];
              },
              icon: const Icon(Icons.close),
            ),
          ),
        ),
      ),
    );
  }
}

class ZapSplitUserContainer extends StatelessWidget {
  const ZapSplitUserContainer({
    super.key,
    required this.metadata,
    required this.isPresent,
    required this.onRemoveUser,
    required this.pubkeysList,
    required this.onAddUser,
  });

  final Metadata metadata;
  final bool isPresent;
  final Function(String p1) onRemoveUser;
  final ValueNotifier<List<String>> pubkeysList;
  final Function(String p1) onAddUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
        vertical: kDefaultPadding / 2,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kDefaultPadding),
        color: Theme.of(context).primaryColorLight,
        border: Border.all(
          color: isPresent ? kGreen : kTransparent,
        ),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: kDefaultPadding / 4,
      ),
      child: Row(
        children: [
          ProfilePicture2(
            image: metadata.picture,
            pubkey: metadata.pubkey,
            size: 30,
            padding: 3,
            strokeWidth: 1,
            strokeColor: Theme.of(context).primaryColorDark,
            onClicked: () {
              openProfileFastAccess(
                context: context,
                pubkey: metadata.pubkey,
              );
            },
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _userInfo(context),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          _setUserButton(context),
        ],
      ),
    );
  }

  BorderedIconButton _setUserButton(BuildContext context) {
    return BorderedIconButton(
      onClicked: () {
        if (isPresent) {
          onRemoveUser.call(metadata.pubkey);
          pubkeysList.value = [...pubkeysList.value..remove(metadata.pubkey)];
        } else {
          onAddUser.call(metadata.pubkey);
          pubkeysList.value = [...pubkeysList.value..add(metadata.pubkey)];
        }
      },
      primaryIcon: !isPresent ? FeatureIcons.add : FeatureIcons.trash,
      borderColor: Theme.of(context).primaryColorLight,
      iconColor: kWhite,
      firstSelection: true,
      size: 40,
      secondaryIcon: FeatureIcons.trash,
      backGroundColor: !isPresent ? kGreen : kRed,
    );
  }

  Expanded _userInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.name.trim().isNotEmpty
                ? metadata.name
                : Nip19.encodePubkey(metadata.pubkey).nineCharacters(),
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (metadata.about.isNotEmpty)
            Text(
              metadata.about,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(color: kDimGrey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
