class CreatorProvider {
  const CreatorProvider({
    required this.pubkey,
    required this.url,
  });

  final String pubkey;
  final String url;
}

class CreatorPlan {
  const CreatorPlan({
    required this.method,
    required this.id,
    required this.name,
    required this.amount,
    required this.interval,
    required this.currency,
  });

  final String method;
  final String id;
  final String name;
  final String amount;
  final String interval;
  final String currency;
}

class CreatorMethod {
  const CreatorMethod({
    required this.id,
    required this.displayName,
    required this.plans,
  });

  final String id;
  final String displayName;
  final List<CreatorPlan> plans;
}

class CreatorSubscriptionData {
  const CreatorSubscriptionData({
    required this.gatewayPubkey,
    required this.methods,
  });

  final String gatewayPubkey;
  final List<CreatorMethod> methods;

  bool get hasPlans => methods.isNotEmpty;

  static CreatorSubscriptionData fromKind30164Tags(List<List<String>> tags) {
    final methodsMap = <String, Map<String, dynamic>>{};
    final prices = <Map<String, String>>[];
    final currencies = <String, String>{};
    String gatewayPubkey = '';

    for (final tag in tags) {
      if (tag.isEmpty) {
        continue;
      }
      final key = tag[0];
      final values = tag.sublist(1);

      if (key == 'gateway' && values.isNotEmpty) {
        gatewayPubkey = values[0];
      } else if (key == 'method' && values.length >= 2) {
        methodsMap[values[0]] = {
          'id': values[0],
          'display_name': values[1],
        };
      } else if (key == 'price' && values.length >= 5) {
        prices.add({
          'method': values[0],
          'id': values[1],
          'name': values[2],
          'amount': values[3],
          'interval': values[4],
        });
      } else if (key == 'currency' && values.length >= 2) {
        currencies[values[0]] = values[1];
      }
    }

    final methods = methodsMap.entries.map((entry) {
      final methodId = entry.key;
      final plans = prices
          .where((p) => p['method'] == methodId)
          .map(
            (p) => CreatorPlan(
              method: methodId,
              id: p['id']!,
              name: p['name']!,
              amount: p['amount']!,
              interval: p['interval']!,
              currency: currencies[methodId] ?? '',
            ),
          )
          .toList();

      return CreatorMethod(
        id: methodId,
        displayName: entry.value['display_name'] as String,
        plans: plans,
      );
    }).toList();

    return CreatorSubscriptionData(
      gatewayPubkey: gatewayPubkey,
      methods: methods,
    );
  }
}
