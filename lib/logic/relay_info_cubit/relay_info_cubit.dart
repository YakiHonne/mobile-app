import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/relay_info.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/relays_collection.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

part 'relay_info_state.dart';

class RelayInfoCubit extends Cubit<RelayInfoState> with LaterFunction {
  RelayInfoCubit()
      : super(
          const RelayInfoState(
            refresh: false,
            relayInfos: {},
            collections: [],
            isLoading: false,
            globalRelays: [],
            relayContacts: {},
            networkRelays: [],
            relayFavored: {},
          ),
        );

  final _pendingRelays = <String>{};

  bool isRelaysCollectionsLoaded = false;
  bool isFavoredRelaysLoaded = false;

  void init() {
    getGlobalRelays();
    buildNetworkRelays();

    if (!isRelaysCollectionsLoaded) {
      getRelaysCollections();
      isRelaysCollectionsLoaded = true;
    }

    if (!isFavoredRelaysLoaded) {
      getFavoredRelays();
      isFavoredRelaysLoaded = true;
    }
  }

  Future<void> getRelaysInfo() async {
    if (_pendingRelays.isEmpty) {
      return;
    }

    final relaysToProcess = List<String>.from(_pendingRelays);
    _pendingRelays.clear();

    final storedRelayInfos = await nc.db.loadRelayInfoByRelays(relaysToProcess);

    if (storedRelayInfos.isNotEmpty) {
      final relayInfos = <String, RelayInfo>{};

      for (final sri in storedRelayInfos) {
        relayInfos[sri.url] = sri;

        if ((sri.lastUpdated + 7200) < currentUnixTimestampSeconds()) {
          relaysToProcess.remove(sri.url);
        }
      }

      updateRelayInfos(relayInfos);
    }

    if (relaysToProcess.isNotEmpty) {
      getRelayInfoEvents(relaysToProcess);
      getRelayInfoMetadata(relaysToProcess);
    }
  }

  Future<void> getRelayInfoMetadata(List<String> relaysToProcess) async {
    final relaysMetadata = await Future.wait(
      relaysToProcess.map(
        (e) => RelayInfo.get(e),
      ),
    );

    final toBeUpdatedRelayInfos = Map<String, RelayInfo>.from(state.relayInfos);

    for (int i = 0; i < relaysToProcess.length; i++) {
      final r = relaysToProcess[i];

      late RelayInfo submittedRelayInfo;
      final newRelayInfo = relaysMetadata[i];
      final oldRelayInfo = toBeUpdatedRelayInfos[r];

      if (oldRelayInfo != null && newRelayInfo != null) {
        submittedRelayInfo = newRelayInfo.copyWith(
          latency: oldRelayInfo.latency,
          isPaid: newRelayInfo.isPaid ? null : oldRelayInfo.isPaid,
          isAuth: newRelayInfo.isAuth ? null : oldRelayInfo.isAuth,
          location: oldRelayInfo.location,
          lastUpdated: currentUnixTimestampSeconds(),
        );
      } else if (oldRelayInfo != null) {
        submittedRelayInfo = oldRelayInfo;
      } else if (newRelayInfo != null) {
        submittedRelayInfo = newRelayInfo;
      } else {
        submittedRelayInfo = RelayInfo(
          name: r,
          description: '',
          pubkey: '',
          contact: '',
          nips: const [],
          software: '',
          icon: '',
          version: '',
          url: r,
          location: '',
          latency: '',
          isPaid: false,
          isAuth: false,
          lastUpdated: currentUnixTimestampSeconds(),
        );
      }

      toBeUpdatedRelayInfos[r] = submittedRelayInfo;
    }
    nc.db.saveRelayInfoList(toBeUpdatedRelayInfos.values.toList());
    updateRelayInfos(toBeUpdatedRelayInfos);
  }

  Future<void> getRelayInfoEvents(List<String> relaysToProcess) async {
    final events = await NostrFunctionsRepository.getEventsAsync(
      dTags: [
        ...relaysToProcess.map(
          (e) => '$e/',
        ),
        // ...relaysToProcess,
        // ...relaysToProcess.map(
        //   (e) => '$e/%7C',
        // ),
      ],
      timeout: 5,
      source: EventsSource.relays,
      includeIds: false,
      relyOnLongestTags: true,
      kinds: [EventKind.RELAY_DISCOVERY],
      pubkeys: [
        '9ba0ce3dcc28c26da0d0d87fa460c78b602a180b61eb70b62aba04505c6331f4',
        '9bbbb845e5b6c831c29789900769843ab43bb5047abe697870cb50b6fc9bf923',
        '9bb7cd94d7b688a4070205d9fb5e9cca6bd781fe7cabe780e19fdd23a036e0a1',
        'abcde937081142db0d50d29bf92792d4ee9b3d79a83c483453171a6004711832',
      ],
    );

    final toBeUpdatedRelayInfos = Map<String, RelayInfo>.from(state.relayInfos);

    for (final e in events) {
      final r = e.dTag;

      if (r != null && r.isNotEmpty) {
        final cleanRelay = Relay.clean(r) ?? r;
        final relayInfo = toBeUpdatedRelayInfos[cleanRelay] ??
            toBeUpdatedRelayInfos[r] ??
            RelayInfo(
              name: r,
              description: '',
              pubkey: '',
              contact: '',
              nips: const [],
              software: '',
              icon: '',
              version: '',
              url: r,
              location: '',
              latency: '',
              isPaid: false,
              isAuth: false,
              lastUpdated: currentUnixTimestampSeconds(),
            );

        String latency = '';
        bool isPaid = false;
        bool isAuth = false;
        String location = '';

        for (final tag in e.tags) {
          if (tag.length > 1) {
            if ((tag[0] == 'R' && tag[1] == 'auth') || relayInfo.isAuth) {
              isAuth = true;
            }

            if ((tag[0] == 'R' && tag[1] == 'payment') || relayInfo.isPaid) {
              isPaid = true;
            }

            if (tag[0] == 'rtt-open') {
              latency = tag[1];
            }

            if (tag[0] == 'l' && tag[1].length == 2) {
              location = tag[1];
            }
          }
        }

        toBeUpdatedRelayInfos[cleanRelay] = relayInfo.copyWith(
          latency: latency,
          isPaid: isPaid,
          isAuth: isAuth,
          location: location,
          lastUpdated: currentUnixTimestampSeconds(),
        );
      }
    }

    nc.db.saveRelayInfoList(toBeUpdatedRelayInfos.values.toList());
    updateRelayInfos(toBeUpdatedRelayInfos);
  }

  void updateRelayInfos(Map<String, RelayInfo> relayInfos) {
    final oldRelayInfos = Map<String, RelayInfo>.from(state.relayInfos)
      ..addAll(
        relayInfos,
      );

    emit(
      state.copyWith(
        relayInfos: oldRelayInfos,
        refresh: !state.refresh,
      ),
    );
  }

  RelayInfo? getCurrentRelayInfo(String relay) {
    final cleanRelay = Relay.clean(relay) ?? relay;

    final rInfo = state.relayInfos[cleanRelay];

    if (rInfo != null) {
      return rInfo;
    }

    _pendingRelays.add(cleanRelay);

    later(() => getRelaysInfo(), null);

    return null;
  }

  Future<void> getGlobalRelays() async {
    final relays = await nostrRepository.getOnlineRelays();

    emit(
      state.copyWith(
        globalRelays: relays,
      ),
    );
  }

  Future<void> getRelaysCollections() async {
    final data = await HttpFunctionsRepository.get(relaysCollection);

    final collectionsList = data?['collections'];

    if (collectionsList != null && collectionsList is List) {
      final collections = relaysCollectionsFromList(collectionsList);

      emit(
        state.copyWith(
          collections: collections,
        ),
      );
    }
  }

  Future<void> buildNetworkRelays() async {
    final relaySets = await nc.db.loadUserRelayListAll();

    final networkRelays = <String>{};

    for (final ur in relaySets) {
      networkRelays.addAll([...ur.writes, ...ur.reads]);
    }

    emit(state.copyWith(
      networkRelays: networkRelays.toList(),
    ));
  }

  Future<List<String>> getRelayContacts(String relay) async {
    if (canSign()) {
      final r = state.relayContacts[relay] ?? [];

      if (r.isNotEmpty) {
        return r;
      }

      final contacts = await nc.db.getPubkeysByRelayAvailability(relay);
      contacts.remove(currentSigner!.getPublicKey());
      contacts.shuffle();

      final map = Map<String, List<String>>.from(state.relayContacts);

      map[relay] = contacts;

      emit(state.copyWith(
        relayContacts: map,
      ));

      return contacts;
    }

    return [];
  }

  Future<void> getFavoredRelays() async {
    if (canSign()) {
      final contacts = <String>[];

      if (contactListCubit.contacts.isEmpty ||
          contactListCubit.contacts.length <= 5) {
        contacts.addAll(
          (await contactListCubit.loadContactList(yakihonneHex))?.contacts ??
              [],
        );
      } else {
        contacts.addAll(contactListCubit.contacts);
      }

      if (contacts.isNotEmpty) {
        final events = await NostrFunctionsRepository.getEventsAsync(
          kinds: [EventKind.FAVORITE_RELAYS],
          pubkeys: contacts,
          limit: 100,
        );

        final relays = <String, List<String>>{};

        for (final e in events) {
          for (final tag in e.tags) {
            if (tag.length > 1) {
              if (tag[0] == 'relay') {
                final r = Relay.clean(tag[1]) ?? tag[1];
                if (relays[r] == null) {
                  relays[r] = [e.pubkey];
                } else if (!relays[r]!.contains(e.pubkey)) {
                  relays[r]!.add(e.pubkey);
                }
              }
            }
          }
        }

        emit(state.copyWith(
          relayFavored: relays,
        ));
      }
    }
  }

  List<String> getFavoredRelayUsers(String relay) {
    return state.relayFavored[relay] ?? [];
  }

  void clear() {
    emit(state.copyWith(
      refresh: !state.refresh,
      relayInfos: {},
      collections: [],
      isLoading: !state.isLoading,
      globalRelays: [],
      relayContacts: {},
      networkRelays: [],
      relayFavored: {},
    ));

    _pendingRelays.clear();
    isFavoredRelaysLoaded = false;
    isRelaysCollectionsLoaded = false;
  }

  @override
  Future<void> close() {
    disposeLater();
    return super.close();
  }
}
