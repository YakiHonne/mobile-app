typedef PricingPlan = ({
  String id,
  String plan,
  String priceId,
  String productId,
  String iapProductId,
  String yakiproIapProductId,
  String paymentProvider,
  String name,
  String price,
  int satsRaw,
  String sats,
  String period,
  String desc,
  bool highlighted,
  List<({String text, bool dim})> features,
});

const kPricingPeriod = '/ month';

String formatSatsPrice(int sats) {
  final s = sats.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write(',');
    }
    buf.write(s[i]);
  }
  return buf.toString();
}
