final npubRegex = RegExp(
  r'@?(nostr:)?@?(npub1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
);

final userRegex = RegExp(
  r'@?(nostr:)?@?(npub1|nprofile1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
);

final newLineRegex = RegExp(r'^\s*[\r\n]');

final relayRegExp = RegExp(
  r'^(ws|wss):\/\/([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^:]+):?([0-9]{1,5})?$',
);

final contentRelayRegExp = RegExp(
  r'(ws|wss):\/\/([0-9]{1,3}(?:\.[0-9]{1,3}){3}|[^:\s]+):?([0-9]{1,5})?',
);

final invoiceRegex = RegExp(
  r'(lnbc[a-zA-Z0-9]+|lnurl[a-zA-Z0-9]+)',
);

final RegExp base64ImageRegex = RegExp(
  r'^data:image\/(png|jpe?g|gif|webp|bmp|svg\+xml);base64,[A-Za-z0-9+/]+=*$',
  caseSensitive: false,
);

final hashtagsRegExp =
    RegExp(r'#([A-Za-zÀ-ÖØ-öø-ÿ0-9]+(-[A-Za-zÀ-ÖØ-öø-ÿ0-9]+)*)');

final RegExp audioUrlRegex = RegExp(
  r'^https?:\/\/.*\.(mp3|wav|ogg|m4a|aac|flac|wma|opus)(\?.*)?$',
  caseSensitive: false,
);

final wordsRegExp = RegExp(r'\S+');

final urlRegExp = RegExp(
  r'((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~,~#=]{1,256}\.[a-zA-Z0-9]{2,20}(:\d{1,5})?(\/[-a-zA-Z0-9@:%_,\+.~#?&\/=]*[-a-zA-Z0-9@:%_\+.~#?&\/=])?',
);

final urlRegex2 = RegExp(r'https?://[\w./?=&-]+');

final urlRegex3 = RegExp(r'(?<=\S)(https?://[^\s]+)');

final imageUrlRegex =
    RegExp(r'https?:\/\/.*\.(?:jpg|jpeg|png|gif|bmp|webp|svg)(\?.*)?$');

final youtubeRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:watch\?v=|embed\/|v\/|shorts\/|playlist\?list=)|youtu\.be\/)([\w-]{11,})',
);

final discordRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:discord\.gg\/|discord(?:app)?\.com\/invite\/)([\w-]+)',
);

final telegramRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:t\.me\/|telegram\.me\/)([\w-]+)',
);

final xRegExp = RegExp(
  r'(?:https?:\/\/)?(?:www\.)?(?:x\.com|twitter\.com)\/(?:#!\/)?(\w+)(?:\/status\/(\d+))?',
);

final emailRegExp = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

final hexRegExp = RegExp(
  r'^#[0-9a-fA-F]{6}',
);

final nostrSchemeRegex = RegExp(
  r'(nostr:)?(npub1|nevent1|naddr1|note1|nprofile1|nrelay1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
  caseSensitive: false,
  dotAll: true,
);

final nostrContentEventRegex = RegExp(
  r'(nostr:)?(nevent1|naddr1|note1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
  caseSensitive: false,
  dotAll: true,
);

final emailNamingRegex = RegExp(
  r'^[a-zA-Z0-9]+$',
);

final nostrNaddrRegex = RegExp(
  r'(nostr:)?(naddr1)([qpzry9x8gf2tvdw0s3jn54khce6mua7l]+)([\\S]*)',
  caseSensitive: false,
  dotAll: true,
);

final RegExp webSocketUrlRegex = RegExp(
  r'^wss?://([a-zA-Z0-9-]+\.)*[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(:[0-9]{1,5})?(/[^\s]*)?$',
);

final rtlPattern = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\u0590-\u05FF]',
);
