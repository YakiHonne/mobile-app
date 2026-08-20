import 'package:dio/dio.dart';
import 'package:nostr_core_enhanced/nostr/nostr.dart';
import 'package:nostr_core_enhanced/pomegranate/pomegranate.dart';

import '../../repositories/http_functions_repository.dart';
import '../../repositories/nostr_functions_repository.dart';
import '../../utils/utils.dart';

/// Re-exported so callers get the protocol and this app's policy from one
/// import, rather than having to know which half a given symbol lives in.
export 'package:nostr_core_enhanced/pomegranate/pomegranate.dart';

/// This app's Pomegranate deployment policy, plus the seams the shared
/// protocol code in `nostr_core_enhanced/pomegranate` needs from it.
///
/// The protocol itself lives in the package; only what legitimately differs
/// between clients is here. Keep it that way — sharing these constants would
/// re-couple the two apps' account generations.

/// Operators offered when recovering an account that has no persisted
/// [PomSetup], i.e. one registered before setups were stored.
///
/// Those accounts are 3-of-5 across an older operator set, two members of
/// which ([kPomLegacyOperatorUrls]) the shared list no longer offers. Without
/// them a user is left with exactly three reachable operators and no margin
/// if one is down — so recovery searches the union, while new accounts are
/// created only against [kPomOperatorUrls].
const kPomRecoveryOperatorUrls = kPomOperatorUrls;

/// The app's configured HTTP client. Its cookie jar is what the central's
/// OAuth handshake depends on, so the protocol code must not build its own.
Future<Dio> pomGetDio() => HttpFunctionsRepository.getDio();

/// Publishes the kind 16440 setup event through this app's relay stack.
Future<void> pomPublishEvent(Event event, List<String> relays) async {
  await NostrFunctionsRepository.sendEvent(
    event: event,
    relays: relays,
    setProgress: false,
  );
}

/// Routes protocol-side failures into the app logger. Discovery is
/// best-effort, so these are logged rather than surfaced.
void pomLogError(Object error) => lg.i(error);
