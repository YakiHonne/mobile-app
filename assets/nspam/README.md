# nspam model assets

`model.txt` and the calibration points in `calibration.json` are adapted from
Wisp's on-device nspam classifier at commit
[`2e56fbd3c89ca280263c5543079ddd9ea5aa0ca9`](https://github.com/barrydeen/wisp/tree/2e56fbd3c89ca280263c5543079ddd9ea5aa0ca9).
The accompanying Wisp MIT license is in this directory. The Dart feature
extractor and LightGBM evaluator are ports of the corresponding Wisp code.
Full NFKC normalization uses `unorm_dart`; emoji feature ranges are derived
from Unicode 17.0's `Emoji_Presentation` and `Extended_Pictographic` data
([Unicode data file](https://www.unicode.org/Public/17.0.0/ucd/emoji/emoji-data.txt)).

The classifier scores an author's recent local kind-1 notes. A high score only
collapses that author's replies into a reversible section; it does not remove
or alter Nostr events. Users can expand the section, safelist an author, or
disable the filter in Content Moderation settings.

The training labels are judgments about accounts and can be wrong. Treat model
scores as suggestions, not definitive claims about an author.
