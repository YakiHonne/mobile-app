/// Namecoin NIP-05 support for YakiHonne.
///
/// Resolves Namecoin `.bit` domains to Nostr pubkeys via ElectrumX servers,
/// providing blockchain-based identity verification as an alternative to
/// the standard HTTP-based NIP-05 flow.
///
/// Ported from Amethyst (MIT License, Vitor Pamplona).

export 'electrumx_client.dart';
export 'electrumx_server.dart';
export 'namecoin_lookup_cache.dart';
export 'namecoin_name_resolver.dart';
export 'namecoin_name_service.dart';
export 'namecoin_settings.dart';
export 'namecoin_shared_preferences.dart';
