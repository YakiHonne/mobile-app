import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nostr_core_enhanced/models/models.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';

import '../../logic/metadata_cubit/metadata_cubit.dart';
import '../../logic/relay_info_cubit/relay_info_cubit.dart';
import '../../logic/single_event_cubit/single_event_cubit.dart';
import '../../utils/utils.dart';

class MetadataProvider extends HookWidget {
  const MetadataProvider({
    super.key,
    required this.child,
    required this.pubkey,
    this.search = true,
    this.loadNip05 = true,
  });

  final Widget Function(Metadata, bool) child;
  final String pubkey;
  final bool search;
  final bool loadNip05;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      if (search && pubkey.isNotEmpty) {
        metadataCubit.requestMetadata(pubkey);
      }
      return null;
    }, [pubkey, search]);

    return BlocSelector<MetadataCubit, MetadataState, (Metadata?, bool)>(
      selector: (state) => (
        state.metadataCache[pubkey],
        state.nip05Status[pubkey] ?? false,
      ),
      builder: (context, data) {
        final (metadata, nip05Valid) = data;

        return child.call(
          metadata ?? Metadata.empty(pubkey: pubkey),
          nip05Valid,
        );
      },
    );
  }
}

class SingleEventProvider extends HookWidget {
  const SingleEventProvider({
    super.key,
    required this.id,
    required this.isReplaceable,
    required this.child,
  });

  final String id;
  final bool isReplaceable;
  final Widget Function(Event? event) child;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      singleEventCubit.getProviderEvent(id, isReplaceable);
      return null;
    }, []);

    return BlocSelector<SingleEventCubit, SingleEventState, Event?>(
      key: ValueKey(id),
      selector: (state) => state.events[id],
      builder: (context, event) => child(event),
    );
  }
}

class MutedUserProvider extends StatelessWidget {
  const MutedUserProvider({
    super.key,
    required this.pubkey,
    required this.child,
  });

  final String pubkey;
  final Widget Function(bool) child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: nostrRepository.mutesStream,
      builder: (context, snapshot) =>
          child.call(snapshot.data?.usersMutes.contains(pubkey) ?? false),
    );
  }
}

class RelayInfoProvider extends HookWidget {
  const RelayInfoProvider({
    super.key,
    required this.relay,
    required this.child,
  });

  final String relay;
  final Widget Function(RelayInfo? info) child;

  @override
  Widget build(BuildContext context) {
    useMemoized(() {
      relayInfoCubit.getCurrentRelayInfo(relay);
      return null;
    }, []);

    return BlocSelector<RelayInfoCubit, RelayInfoState, RelayInfo?>(
      key: ValueKey(relay),
      selector: (state) => state.relayInfos[relay],
      builder: (context, event) => child(event),
    );
  }
}
