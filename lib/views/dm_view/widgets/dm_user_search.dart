import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nips/nip_019.dart';

import '../../../logic/dms_cubit/dms_cubit.dart';
import '../../../utils/utils.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/nip05_component.dart';
import '../../widgets/profile_picture.dart';
import 'dm_details.dart';

class DmUserSearch extends HookWidget {
  DmUserSearch({super.key}) {
    umamiAnalytics.trackEvent(screenName: 'Private message search view');
  }
  static const routeName = '/dmUserSearchView';

  static Route route() {
    return CupertinoPageRoute(
      builder: (_) => DmUserSearch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    final authors = useState(<Metadata>[]);

    return Scaffold(
      appBar: CustomAppBar(
        title: context.t.newMessage.capitalizeFirst(),
        notElevated: false,
      ),
      body: CustomScrollView(
        slivers: [
          _appbar(textEditingController, context, authors),
          const SliverToBoxAdapter(
            child: SizedBox(height: kDefaultPadding / 2),
          ),
          _itemsList(authors),
          const SliverToBoxAdapter(
            child: SizedBox(height: kDefaultPadding),
          ),
        ],
      ),
    );
  }

  SliverPadding _itemsList(ValueNotifier<List<Metadata>> authors) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      sliver: SliverList.separated(
        separatorBuilder: (context, index) => const SizedBox(
          height: kDefaultPadding / 2,
        ),
        itemBuilder: (context, index) {
          final author = authors.value[index];

          return CommonMetadataBox(
            metadata: author,
            onClick: () {
              context.read<DmsCubit>().updateReadedTime(
                    author.pubkey,
                  );

              Navigator.pushNamed(
                context,
                DmDetails.routeName,
                arguments: [
                  author.pubkey,
                ],
              );
            },
          );
        },
        itemCount: authors.value.length,
      ),
    );
  }

  SliverAppBar _appbar(TextEditingController textEditingController,
      BuildContext context, ValueNotifier<List<Metadata>> authors) {
    return SliverAppBar(
      titleSpacing: 0,
      automaticallyImplyLeading: false,
      pinned: true,
      actions: const [
        SizedBox.shrink(),
      ],
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: _textfield(textEditingController, context, authors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CupertinoTextField _textfield(TextEditingController textEditingController,
      BuildContext context, ValueNotifier<List<Metadata>> authors) {
    return CupertinoTextField(
      controller: textEditingController,
      placeholder: context.t.searchNameNpub.capitalizeFirst(),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Icon(
          CupertinoIcons.search,
          color: CupertinoColors.systemGrey,
          size: 20,
        ),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Theme.of(context).cardColor,
      ),
      suffix: IconButton(
        onPressed: () {
          textEditingController.clear();
          authors.value = [];
        },
        icon: const Icon(
          Icons.close,
          color: CupertinoColors.systemGrey,
        ),
      ),
      onChanged: (search) async {
        if (search.isEmpty) {
          authors.value = [];
        } else {
          if (search.startsWith('npub')) {
            final author = await metadataCubit
                .getFutureMetadata(Nip19.decodePubkey(search));

            if (author != null) {
              authors.value = [author];
            } else {
              authors.value = [];
            }
          } else if (search.startsWith('nprofile')) {
            final s = Nip19.decodeShareableEntity(search);
            final auth = s['author'] as String?;

            if (auth != null && auth.isNotEmpty) {
              final author = await metadataCubit.getFutureMetadata(auth);

              if (author != null) {
                authors.value = [author];
              } else {
                authors.value = [];
              }
            }
          } else if (search.length == 64) {
            final author = await metadataCubit.getFutureMetadata(search);

            if (author != null) {
              authors.value = [author];
            } else {
              authors.value = [];
            }
          } else {
            authors.value = await metadataCubit.searchCacheMetadatas(search);
          }
        }
      },
    );
  }
}

class CommonMetadataBox extends StatelessWidget {
  const CommonMetadataBox({
    super.key,
    required this.metadata,
    required this.onClick,
  });

  final Metadata metadata;
  final Function() onClick;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onClick,
      child: Row(
        children: <Widget>[
          ProfilePicture2(
            size: 35,
            image: metadata.picture,
            pubkey: metadata.pubkey,
            padding: 0,
            strokeWidth: 0,
            strokeColor: kTransparent,
            onClicked: onClick,
          ),
          const SizedBox(
            width: kDefaultPadding / 2,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.getName(),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Nip05Component(
                  metadata: metadata,
                  useNip05: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
