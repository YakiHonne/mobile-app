import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/metadata.dart';

import '../../../logic/search_user_cubit/search_user_cubit.dart';
import '../../../routes/navigator.dart';
import '../../../utils/bot_toast_util.dart';
import '../../../utils/utils.dart';
import '../../search_view/search_view.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/data_providers.dart';
import '../../widgets/empty_list.dart';
import '../../widgets/profile_picture.dart';
import 'send_using_lightning_address.dart';

class SendByUserSearch extends HookWidget {
  const SendByUserSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final suggestions = useState<List<String>>([]);
    final children = <Widget>[];
    final searchTextController = useTextEditingController();
    final searchText = useState('');

    useMemoized(() async {
      suggestions.value = await contactListCubit.getRandomSuggestion();
    });

    children.add(
      const SliverToBoxAdapter(
        child: SizedBox(
          height: kDefaultPadding / 2,
        ),
      ),
    );

    children.add(
      SliverToBoxAdapter(
        child: BlocBuilder<SearchUserCubit, SearchUserState>(
          builder: (context, state) {
            return TextFormField(
              autofocus: true,
              controller: searchTextController,
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: (search) async {
                searchText.value = search;

                if (search.isEmpty) {
                  context.read<SearchUserCubit>().emptyAuthorsList();
                } else {
                  context.read<SearchUserCubit>().getAuthors(
                    search,
                    (user) {
                      onUserSelected.call(user, context);
                    },
                  );
                }
              },
              decoration: InputDecoration(
                hintText: context.t.searchNameNpub.capitalizeFirst(),
                prefixIcon: const Icon(
                  CupertinoIcons.search,
                  size: 20,
                ),
                suffixIcon: searchText.value.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchTextController.clear();
                          searchText.value = '';
                          context.read<SearchUserCubit>().emptyAuthorsList();
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );

    children.add(
      const SliverToBoxAdapter(
        child: SizedBox(
          height: kDefaultPadding / 1.5,
        ),
      ),
    );

    if (suggestions.value.isNotEmpty && searchText.value.isEmpty) {
      children.add(
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: kDefaultPadding / 1.5,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 7.5),
                child: Text(
                  context.t.suggestions,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).highlightColor,
                      ),
                ),
              ),
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final pubkey = suggestions.value[index];

                    return _userBox(pubkey, context);
                  },
                  itemCount: suggestions.value.length,
                ),
              )
            ],
          ),
        ),
      );
    }

    children.add(
      const SliverToBoxAdapter(
        child: SizedBox(
          height: kDefaultPadding / 2,
        ),
      ),
    );

    children.add(
      SliverToBoxAdapter(
        child: BlocBuilder<SearchUserCubit, SearchUserState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const SearchLoading();
            } else if (state.authors.isEmpty) {
              return EmptyList(
                description: context.t.noUserCanBeFound.capitalizeFirst(),
                icon: FeatureIcons.user,
              );
            }

            final contactList = contactListCubit.contacts;

            return ListView.separated(
              separatorBuilder: (context, index) => const SizedBox(
                height: kDefaultPadding / 2,
              ),
              shrinkWrap: true,
              primary: false,
              itemBuilder: (context, index) {
                final metadata = state.authors[index];

                return SearchAuthorContainer(
                  key: ValueKey(metadata.pubkey),
                  metadata: metadata,
                  youFollow: contactList.contains(metadata.pubkey),
                  onClick: () => onUserSelected.call(metadata, context),
                );
              },
              itemCount: state.authors.length,
            );
          },
        ),
      ),
    );

    children.add(
      const SliverToBoxAdapter(
        child: SizedBox(height: kBottomNavigationBarHeight),
      ),
    );

    return BlocProvider(
      create: (context) => SearchUserCubit(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.t.contacts,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding / 2,
          ),
          child: CustomScrollView(
            slivers: children,
          ),
        ),
      ),
    );
  }

  MetadataProvider _userBox(String pubkey, BuildContext context) {
    return MetadataProvider(
      pubkey: pubkey,
      child: (metadata, isNip05Valid) {
        return GestureDetector(
          onTap: () => onUserSelected.call(metadata, context),
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: 75,
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 4,
            ),
            child: Column(
              children: [
                ProfilePicture2(
                  size: 60,
                  pubkey: metadata.pubkey,
                  image: metadata.picture,
                  padding: 0,
                  strokeWidth: 0,
                  strokeColor: kTransparent,
                  onClicked: () {
                    onUserSelected.call(metadata, context);
                  },
                ),
                const SizedBox(
                  height: kDefaultPadding / 3,
                ),
                Expanded(
                  child: Text(
                    metadata.getName(),
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onUserSelected(Metadata metadata, BuildContext context) {
    final t = metadata.getLightningAddress();

    if (t == null) {
      BotToastUtils.showError(context.t.invalidInvoiceLnurl);
    } else {
      YNavigator.pushPage(
        context,
        (context) => SendUsingLightningAddress(
          lnLnurl: t,
          metadata: metadata,
          isManual: false,
        ),
      );
    }
  }
}
