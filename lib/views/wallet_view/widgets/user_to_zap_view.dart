// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../../logic/search_user_cubit/search_user_cubit.dart';
import '../../../utils/utils.dart';
import '../../search_view/search_view.dart';
import '../../widgets/dotted_container.dart';
import '../../widgets/empty_list.dart';

class UserToZap extends HookWidget {
  final Function(Metadata) onUserSelected;

  const UserToZap({
    super.key,
    required this.onUserSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();

    final contactList = useMemoized(() {
      return contactListCubit.contacts;
    });

    return BlocProvider(
      create: (context) => SearchUserCubit(),
      child: Container(
        width: double.infinity,
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
          initialChildSize: 0.8,
          minChildSize: 0.40,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding / 2,
            ),
            child: Column(
              children: [
                const Center(
                  child: ModalBottomSheetHandle(),
                ),
                _textfield(textEditingController, context),
                const SizedBox(height: kDefaultPadding / 2),
                _itemsList(contactList),
                const SizedBox(height: kDefaultPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Expanded _itemsList(List<String> contactList) {
    return Expanded(
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

          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(
              height: kDefaultPadding / 2,
            ),
            itemBuilder: (context, index) {
              final metadata = state.authors[index];

              return SearchAuthorContainer(
                key: ValueKey(metadata.pubkey),
                metadata: metadata,
                youFollow: contactList.contains(metadata.pubkey),
                onClick: () => onUserSelected.call(metadata),
              );
            },
            itemCount: state.authors.length,
          );
        },
      ),
    );
  }

  TextFormField _textfield(
      TextEditingController textEditingController, BuildContext context) {
    return TextFormField(
      controller: textEditingController,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (search) async {
        context.read<SearchUserCubit>().getAuthors(
          search,
          (user) {
            onUserSelected.call(user);
          },
        );
      },
      decoration: InputDecoration(
        hintText: context.t.search.capitalizeFirst(),
        suffixIcon: IconButton(
          onPressed: () {
            textEditingController.clear();
            context.read<SearchUserCubit>().emptyAuthorsList();
          },
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}
