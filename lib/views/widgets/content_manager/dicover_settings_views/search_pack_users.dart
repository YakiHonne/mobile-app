import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../logic/search_user_cubit/search_user_cubit.dart';
import '../../../../utils/utils.dart';
import '../../../search_view/search_view.dart';
import '../../dotted_container.dart';
import '../../empty_list.dart';
import '../../fluid_scaffold.dart';
import '../../modal_sheet_container.dart';

class SearchPackUsers extends HookWidget {
  const SearchPackUsers({
    super.key,
    this.isModal = false,
    required this.pubkeys,
    required this.onPubkeysUpdates,
  });

  final Set<String> pubkeys;
  final Function(Set<String>) onPubkeysUpdates;
  final bool isModal;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final searchTextController = useTextEditingController();
    final searchText = useState('');
    final debounceTimer = useRef<Timer?>(null);
    final selectedPubkeys = useState<Set<String>>(pubkeys);

    useEffect(() {
      return () => debounceTimer.value?.cancel();
    }, []);

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
                debounceTimer.value?.cancel();

                if (search.isEmpty) {
                  context.read<SearchUserCubit>().emptyAuthorsList();
                } else {
                  debounceTimer.value =
                      Timer(const Duration(milliseconds: 500), () {
                    context.read<SearchUserCubit>().getAuthors(
                      search,
                      (user) {
                        onUserSelected.call(
                          pubkey: user.pubkey,
                          context: context,
                          selectedPubkeys: selectedPubkeys,
                        );
                      },
                    );
                  });
                }
              },
              decoration: InputDecoration(
                hintText: context.t.searchNameNpub.capitalizeFirst(),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 20,
                ),
                suffixIcon: searchText.value.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchTextController.clear();
                          searchText.value = '';
                          context.read<SearchUserCubit>().emptyAuthorsList();
                        },
                        icon: const Icon(LucideIcons.x),
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
                  onClick: () => onUserSelected.call(
                    pubkey: metadata.pubkey,
                    context: context,
                    selectedPubkeys: selectedPubkeys,
                  ),
                  hasAction: true,
                  isAdded: selectedPubkeys.value.contains(metadata.pubkey),
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

    final view = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding / 2,
      ),
      child: CustomScrollView(
        slivers: [
          // Modal path renders in a sheet, not a FluidScaffold — no bar to
          // clear there.
          if (!isModal)
            SliverPadding(
              padding: EdgeInsets.only(top: fluidScaffoldTopInset(context)),
            ),
          ...children,
        ],
      ),
    );

    if (isModal) {
      return ModalSheetContainer(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BlocProvider(
          create: (context) => SearchUserCubit(),
          child: Column(
            children: [
              ModalBottomSheetAppbar(
                title: context.t.contacts,
                isBack: false,
              ),
              Expanded(child: view),
            ],
          ),
        ),
      );
    }

    return BlocProvider(
      create: (context) => SearchUserCubit(),
      child: FluidScaffold(
        title: context.t.contacts,
        body: view,
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

    onPubkeysUpdates.call(selectedPubkeys.value);
  }
}
