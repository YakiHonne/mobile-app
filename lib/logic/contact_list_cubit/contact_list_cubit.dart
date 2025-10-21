import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/models.dart';

import '../../globals.dart';
import '../../models/app_models/diverse_functions.dart';

part 'contact_list_state.dart';

class ContactListCubit extends Cubit<ContactListState> {
  ContactListCubit() : super(const ContactListState(refresh: false));

  List<String> contacts = [];

  Future<void> syncContacts() async {
    final contactList = await getContactList(currentSigner!.getPublicKey());

    contacts = contactList?.contacts ?? [];
  }

  Future<ContactList?> getContactList(String pubkey) async {
    return nc.db.loadContactList(pubkey);
  }

  Future<ContactList?> loadContactList(String pubKey) async {
    return nc.loadContactList(pubKey);
  }

  Future<void> saveContactList(ContactList contactList) async {
    return nc.db.saveContactList(contactList);
  }

  Future<void> addContact(String contact) async {
    final contactList = await nc.publishAddContacts(
      [contact],
      currentUserRelayList.writes,
      currentSigner!,
    );

    contacts = contactList?.contacts ?? contacts;

    if (!isClosed) {
      emit(state.copyWith(refresh: !state.refresh));
    }
  }

  Set<String> getRandomPubkeys({required int number}) {
    final items = List<String>.from(contacts);
    final itemsList = items.take(number).toList();
    itemsList.shuffle(Random());
    final random = itemsList.toSet();

    return random;
  }

  Future<ContactList?> setContacts(List<String> c) async {
    final contactList = await nc.publishUpdateContacts(
      c,
      currentUserRelayList.writes,
      currentSigner!,
      nostrRepository.mutes,
    );

    syncContacts();

    return contactList;
  }

  Future<void> removeContact(String contact) async {
    final contactList = await nc.publishRemoveContacts(
      [contact],
      currentUserRelayList.writes,
      currentSigner!,
    );

    contacts = contactList?.contacts ?? contacts;

    if (!isClosed) {
      emit(state.copyWith(refresh: !state.refresh));
    }
  }

  Future<List<String>> getRandomSuggestion() async {
    contacts.shuffle();

    if (contacts.length <= 10) {
      return contacts;
    } else {
      return contacts.sublist(0, 10);
    }
  }

  Future<List<String>> contactsAsync() async {
    if (!isDisconnected()) {
      contacts =
          (await nc.loadContactList(currentSigner!.getPublicKey()))?.contacts ??
              [];

      return contacts;
    } else {
      return [];
    }
  }

  Future<List<String>> followedTags() async {
    final contactList = await getContactList(currentSigner!.getPublicKey());
    return contactList != null ? contactList.followedTags : [];
  }

  void clear() {
    if (!isClosed) {
      emit(
        state.copyWith(
          refresh: !state.refresh,
        ),
      );
    }
  }
}
