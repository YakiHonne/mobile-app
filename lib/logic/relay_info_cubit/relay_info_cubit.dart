// ignore_for_file: use_build_context_synchronously

import 'package:bot_toast/bot_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nostr_core_enhanced/models/relay_info.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/utils/utils.dart';

import '../../common/mixins/later_function.dart';
import '../../models/app_models/diverse_functions.dart';
import '../../models/relays_collection.dart';
import '../../models/relays_feed.dart';
import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/bot_toast_util.dart';
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
            relayFeeds: RelayFeeds(
              favoriteRelays: [],
              events: [],
            ),
            favoriteUserRelaySets: [],
            userRelaySets: {},
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
    final events = await nostrRepository.fetchRelaysMetadata(relaysToProcess);

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

    _safeEmit(
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

  Future<void> getSearchRelay() async {
    await nc.doQuery(
      [
        Filter(),
      ],
      [],
    );
  }

  Future<List<String>> getActiveGlobalRelays() async {
    if (state.globalRelays.isNotEmpty) {
      return state.globalRelays;
    }

    await getGlobalRelays();

    return state.globalRelays;
  }

  Future<void> getGlobalRelays() async {
    final relays = await nostrRepository.fetchRelays();

    _safeEmit(
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

      _safeEmit(
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

    _safeEmit(state.copyWith(
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

      _safeEmit(state.copyWith(
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

        _safeEmit(state.copyWith(
          relayFavored: relays,
        ));
      }
    }
  }

  // ==================================================
  // FAVORITE RELAYS MANAGEMENT
  // ==================================================

  Future<void> initRelays() async {
    if (canSign()) {
      await loadLocalRelaysData();
      syncFavoriteRelays();
    }
  }

  Future<void> setRelaySet({
    required List<String> relays,
    required String title,
    required String description,
    required String image,
    required String? identifier,
    required Function() onSuccess,
  }) async {
    final event = await Event.genEvent(
      kind: EventKind.RELAY_SET,
      tags: [
        ['d', identifier ?? randomHexString(16)],
        if (title.isNotEmpty) ['title', title],
        if (description.isNotEmpty) ['description', description],
        if (image.isNotEmpty) ['image', image],
        ...relays.map((e) => ['relay', e]),
      ],
      content: '',
      signer: currentSigner,
    );

    if (event != null) {
      final isSuccessful = await NostrFunctionsRepository.sendEvent(
        event: event,
        setProgress: false,
      );

      if (isSuccessful) {
        await nc.db.saveEvent(event);
        BotToastUtils.showSuccess(t.relaySetCreated);
        addRelaySet(UserRelaySet.fromEvent(event));
        onSuccess.call();
      } else {
        BotToastUtils.showError(
          identifier != null
              ? t.errorOnUpdatingRelaySet
              : t.errorOnCreatingRelaySet,
        );
      }
    } else {
      BotToastUtils.showError(t.errorGeneratingEvent);
    }
  }

  Future<void> deleteRelaySet(UserRelaySet relaySet) async {
    final isSuccessful = await NostrFunctionsRepository.deleteEvent(
      eventId: relaySet.id,
    );

    if (isSuccessful) {
      removeRelaySet(relaySet.identifier);
      BotToastUtils.showSuccess(t.relaySetDeleted);
    } else {
      BotToastUtils.showError(t.errorDeletingRelaySet);
    }
  }

  void addRelaySet(UserRelaySet relaySet) {
    final oldMap = Map<String, UserRelaySet>.from(state.userRelaySets);

    oldMap[relaySet.identifier] = relaySet;

    _safeEmit(state.copyWith(
      userRelaySets: oldMap,
    ));
  }

  void removeRelaySet(String identifier) {
    final oldMap = Map<String, UserRelaySet>.from(state.userRelaySets);

    oldMap.remove(identifier);

    _safeEmit(state.copyWith(
      userRelaySets: oldMap,
    ));
  }

  Future<void> updateFavouriteRelays({
    required List<String> relays,
    required List<EventCoordinates> userRelaySets,
  }) async {
    setUpdatedFavoriteRelays(relays: relays, userRelaySets: userRelaySets);

    final isSuccessful = await setFavoriteRelays();

    if (isSuccessful) {
      BotToastUtils.showSuccess(t.relaysListUpdated);
    } else {
      BotToastUtils.showSuccess(t.errorUpdatingRelaysList);
    }
  }

  Future<void> loadLocalRelaysData() async {
    final relaysEvent = await nc.db.loadEvent(
      pubkey: currentSigner!.getPublicKey(),
      kind: EventKind.FAVORITE_RELAYS,
    );

    final relaySets = await nc.db.loadEvents(
      f: Filter(
        kinds: [EventKind.RELAY_SET],
        authors: [currentSigner!.getPublicKey()],
      ),
    );

    setFavoriteRelayFromEvent(
      favouriteRelaysEvent: relaysEvent,
      relaySetEvents: relaySets,
    );
  }

  Future<void> syncFavoriteRelays({bool override = false}) async {
    await Future.delayed(const Duration(seconds: 2));

    final events = await NostrFunctionsRepository.getEventsAsync(
      kinds: [EventKind.FAVORITE_RELAYS, EventKind.RELAY_SET],
      pubkeys: [currentSigner!.getPublicKey()],
      source: EventsSource.relays,
    );

    if (events.isNotEmpty) {
      final favouriteRelaysEvent = events
          .where(
            (e) => e.kind == EventKind.FAVORITE_RELAYS,
          )
          .firstOrNull;

      final relaySetEvents = events
          .where(
            (e) => e.kind == EventKind.RELAY_SET,
          )
          .toList();

      await Future.delayed(const Duration(milliseconds: 500)).then(
        (_) {
          setFavoriteRelayFromEvent(
            favouriteRelaysEvent: favouriteRelaysEvent,
            relaySetEvents: relaySetEvents,
          );
        },
      );
    }
  }

  void setFavoriteRelayFromEvent({
    Event? favouriteRelaysEvent,
    List<Event>? relaySetEvents,
  }) {
    RelayFeeds? relayFeeds;
    List<EventCoordinates> favoriteUserRelaySets = [];
    final userRelaySets = <String, UserRelaySet>{};

    if (favouriteRelaysEvent != null) {
      relayFeeds = RelayFeeds.fromEvent(favouriteRelaysEvent);

      if (relayFeeds.favoriteRelays.isNotEmpty) {
        final cleanRelays = <String>[];

        for (final r in relayFeeds.favoriteRelays) {
          final cr = Relay.clean(r[1]);
          if (cr != null) {
            cleanRelays.add(cr);
          }
        }

        nc.connectRelays(cleanRelays);
      }

      if (relayFeeds.events.isNotEmpty) {
        favoriteUserRelaySets = state.favoriteUserRelaySets
            .where(
              (element) => relayFeeds!.events
                  .any((e) => e.identifier == element.identifier),
            )
            .toList();
      }
    }

    if (relaySetEvents != null) {
      for (final e in relaySetEvents) {
        userRelaySets[e.dTag ?? e.id] = UserRelaySet.fromEvent(e);
      }
    }

    _safeEmit(
      state.copyWith(
        relayFeeds: relayFeeds,
        userRelaySets: userRelaySets,
        favoriteUserRelaySets: favoriteUserRelaySets,
      ),
    );
  }

  Future<bool> setFavoriteRelays() async {
    final event = await state.relayFeeds.toEvent();

    if (event == null) {
      return false;
    }

    nc.db.saveEvent(event);

    return NostrFunctionsRepository.sendEvent(
      event: event,
      setProgress: false,
    );
  }

  List<String> getFavoredRelayUsers(String relay) {
    return state.relayFavored[relay] ?? [];
  }

  void updateFavoriteRelays(String relay) {
    final relays = List<String>.from(state.relayFeeds.favoriteRelays);

    _safeEmit(state.copyWith(
      relayFeeds: state.relayFeeds.copyWith(
        favoriteRelays: relays.contains(relay)
            ? (relays..remove(relay))
            : (relays..add(relay)),
      ),
    ));
  }

  Future<void> setFavoriteRelaysConnection() async {
    final relays = state.relayFeeds.favoriteRelays;

    await nc.connectNonConnectedRelays(relays.toSet());
  }

  Future<void> setAndUpdateFavoriteRelay(String relay) async {
    final cancel = BotToast.showLoading();

    updateFavoriteRelays(relay);
    final isSuccessful = await setFavoriteRelays();

    if (isSuccessful) {
      BotToastUtils.showSuccess(t.relaysListUpdated);
    } else {
      BotToastUtils.showSuccess(t.errorUpdatingRelaysList);
    }

    cancel.call();
  }

  UserRelaySet? getUpdatedFavoriteRelaySet(String identifier) {
    return state.userRelaySets[identifier];
  }

  void setUpdatedFavoriteRelays({
    required List<String> relays,
    required List<EventCoordinates> userRelaySets,
  }) {
    _safeEmit(
      state.copyWith(
        relayFeeds: state.relayFeeds.copyWith(
          favoriteRelays: relays,
          events: userRelaySets,
        ),
        favoriteUserRelaySets: userRelaySets,
      ),
    );
  }

  void clear() {
    _safeEmit(state.copyWith(
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

  // ==================================================
  // SAFE EMIT FUNCTION
  // ==================================================

  /// Safe emit function that checks if cubit is closed before emitting
  void _safeEmit(RelayInfoState newState) {
    if (!isClosed) {
      emit(newState);
    }
  }

  @override
  Future<void> close() {
    disposeLater();
    return super.close();
  }
}
