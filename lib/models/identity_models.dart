const kNip05Domain = 'yakihonne.com';
const kWalletDomain = 'wallet.yakihonne.com';

final _kUsernamePattern = RegExp(r'^[a-z0-9_-]{3,30}$');

/// Lowercase, 3–30, letters/digits/underscore/hyphen. Enforced locally so an
/// obviously bad name never costs a network round trip, and because the name
/// cannot be changed once claimed.
bool isValidUsername(String name) => _kUsernamePattern.hasMatch(name);

/// `https://yakihonne.com/<username>` — a single path segment that reads as a
/// legal username. Returns null for every other shape, which is what keeps
/// nostr entities (too long for the pattern) and multi-segment site routes out
/// of the username deeplink path.
String? usernameFromYakiUrl(String url) {
  final uri = Uri.tryParse(url);

  // A trailing slash adds an empty segment, hence the filter.
  final segments = uri?.pathSegments.where((s) => s.isNotEmpty).toList() ?? [];

  if (uri == null || !uri.host.contains(kNip05Domain) || segments.length != 1) {
    return null;
  }

  final name = segments.first;

  return isValidUsername(name) ? name : null;
}

enum AddressStatus {
  unchecked,
  checking,
  available,
  taken,

  /// Already bound to this account — nothing to claim for this row.
  alreadySet,

  /// Field left blank — this row is opted out of, not claimed.
  skipped,
}

/// Maps an availability response to a row status. `owned` wins over
/// `available`: a name this account already holds reads as taken by the server,
/// but there is nothing left to claim.
AddressStatus addressStatusOf(
  ({bool available, bool owned, String? reason}) r,
) {
  if (r.owned) {
    return AddressStatus.alreadySet;
  }
  return r.available ? AddressStatus.available : AddressStatus.taken;
}

/// Whether pressing "update profile" should also claim [pending] as the Yaki
/// username.
///
/// The username field carries no button of its own, so the claim rides along
/// with the metadata update — but only for a name that is free, legal, and not
/// already claimed. Anything else leaves the account untouched.
bool shouldClaimUsernameOnUpdate({
  required String claimed,
  required String pending,
  required AddressStatus status,
}) =>
    claimed.isEmpty &&
    status == AddressStatus.available &&
    isValidUsername(pending.trim());

/// Opening status for a NIP-05 name field seeded with [seed].
///
/// Only a name the account owns is settled — `alreadySet` renders the field
/// read-only, so seeding it for a yakihonne address the account does not own
/// (set by hand, or claimed elsewhere) would leave the user unable to type a
/// different name. Anything else starts unchecked and gets verified.
AddressStatus seedNip05Status(String seed, String accountNip05) =>
    seed.isNotEmpty && seed == accountNip05
        ? AddressStatus.alreadySet
        : AddressStatus.unchecked;
