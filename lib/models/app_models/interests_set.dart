// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:nostr_core_enhanced/nostr/nostr.dart';

class InterestSet {
  InterestSet({
    required this.interest,
    required this.image,
    required this.onboarding,
    required this.pubkeys,
    required this.subInterests,
  });

  factory InterestSet.fromJson(String source) =>
      InterestSet.fromMap(json.decode(source) as Map<String, dynamic>);

  final String interest;
  final String image;
  final bool onboarding;
  final Set<String> pubkeys;
  final List<String> subInterests;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'interest': interest,
      'image': image,
      'onboarding': onboarding,
      'pubkeys': pubkeys,
      'subInterests': subInterests,
    };
  }

  String toJson() => json.encode(toMap());

  static String st =
      "[{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/freedom.png\",\"main_tag\":\"Freedom\",\"onboarding\":true,\"pubkeys\":[\"npub1trr5r2nrpsk6xkjk5a7p6pfcryyt6yzsflwjmz6r7uj7lfkjxxtq78hdpu\",\"npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9\",\"npub1xw7h0efeg5s8gla2uyu55jh4lfrlgppcjemrwkmdc7lgvhkcz3fqpvumsa\",\"npub1yye4qu6qrgcsejghnl36wl5kvecsel0kxr0ass8ewtqc8gjykxkssdhmd0\",\"npub1xeejes6lu4scttcmzytq5wfad3e6rljpmhc3snqs89xz3jjavfasnuz3mx\",\"npub13ql75nq8rldygpkjke47y893akh5tglqtqzs6cspancaxktthsusvfqcg7\",\"npub1dcgppk89h9flnffrznvhhj2vt9a0ym23ht5gk07l9j8m6l5k95qsze06js\"],\"sub_tags\":[\"freedom\",\"free\",\"speech\",\"free-speech\",\"freespeech\",\"free speech\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/bitcoin.png\",\"main_tag\":\"Bitcoin\",\"onboarding\":true,\"pubkeys\":[\"npub1f4www6qjx43mckpkjld4apyyr76j3aahprvkduh9gc5xec78ypmsmakqh9\",\"npub1s5yq6wadwrxde4lhfs56gn64hwzuhnfa6r9mj476r5s4hkunzgzqrs6q7z\",\"npub17u5dneh8qjp43ecfxr6u5e9sjamsmxyuekrg2nlxrrk6nj9rsyrqywt4tp\",\"npub1j8y6tcdfw3q3f3h794s6un0gyc5742s0k5h5s2yqj0r70cpklqeqjavrvg\",\"npub1pyp9fqq60689ppds9ec3vghsm7s6s4grfya0y342g2hs3a0y6t0segc0qq\",\"npub1dergggklka99wwrs92yz8wdjs952h2ux2ha2ed598ngwu9w7a6fsh9xzpc\",\"npub1qex7yjtuucs6ac49kjujdgytrjsphn5a4pdscu2w3qlprym4zsxqfz82qk\"],\"sub_tags\":[\"blockchain\",\"Blockchain\",\"Bitcoin\",\"bitcoin\",\"BITCOIN\",\"BTC\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/news.png\",\"main_tag\":\"News\",\"onboarding\":true,\"pubkeys\":[\"npub1yfdayudzpzp4y9zj58v4vj5enqw687jae9yc7gtsjwrhy6p9lnyq4fvg3f\",\"npub1f4uyypghstsd8l4sxng4ptwzk6awfm3mf9ux0yallfrgkm6mj6es50r407\",\"npub18cgmdfljv7ldlswsphk08juze53pk2p92pud8hvay6gq6qydva8qpsvnx2\",\"npub1n0sqr4ljf3gcjf4aw07qdllw5fe7yu9pcsaffuxcneygw7t2wzks5thw60\",\"npub1jfujw6llhq7wuvu5detycdsq5v5yqf56sgrdq8wlgrryx2a2p09svwm0gx\",\"npub1guh5grefa7vkay4ps6udxg8lrqxg2kgr3qh9n4gduxut64nfxq0q9y6hjy\",\"npub1yzvxlwp7wawed5vgefwfmugvumtp8c8t0etk3g8sky4n0ndvyxesnxrf8q\",\"npub1hggnx76clxqy5rc3zqtrprw6e9jzvlvxh6js36enkdk8mxsl36esy4wypf\"],\"sub_tags\":[\"News\",\"Media\",\"Social Media\",\"Marty's Ƀent\",\"Cuba\",\"SEC\",\"USA\",\"Right Shift%20\",\"ThaiNostrich\",\"SOCIAL MEDIA\",\"Right Shift\",\"China\",\"Africa\",\"ukraine\",\"War\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/technology.png\",\"main_tag\":\"Technology\",\"onboarding\":true,\"pubkeys\":[\"npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6\",\"npub1l2vyh47mk2p0qlsku7hg0vn29faehy9hy34ygaclpn66ukqp3afqutajft\",\"npub1xtscya34g58tk0z605fvr788k263gsu6cy9x0mhnm87echrgufzsevkk5s\",\"npub1jlrs53pkdfjnts29kveljul2sm0actt6n8dxrrzqcersttvcuv3qdjynqn\",\"npub1qqqqqqyz0la2jjl752yv8h7wgs3v098mh9nztd4nr6gynaef6uqqt0n47m\",\"npub18ams6ewn5aj2n3wt2qawzglx9mr4nzksxhvrdc4gzrecw7n5tvjqctp424\",\"npub18ams6ewn5aj2n3wt2qawzglx9mr4nzksxhvrdc4gzrecw7n5tvjqctp424\"],\"sub_tags\":[\"Technology\",\"nostrdevs\",\"nostrs-devs\",\"nostr developpement\",\"coding\",\"programming\",\"Digital Transformation\",\"software development\",\"Blockchain\",\"blockchain\",\"Decentralization\",\"Robotics\",\"OpenAI\",\"privacy\",\"Artificial Intelligence\",\"ARTIFICIAL INTELLIGENCE\",\"Tech\",\"TECH\",\"INNOVATION\",\"programming\",\"Cybersecurity\",\"Nvidia\",\"languages\",\"Robots\",\"ai\",\"twitter\",\"Twitter\",\"Apple\",\"Microsoft\",\"Google\",\"Security\",\"TECHNICAL\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/travel.png\",\"main_tag\":\"Travel\",\"onboarding\":true,\"pubkeys\":[\"npub105em547c5m5gdxslr4fp2f29jav54sxml6cpk6gda7xyvxuzmv6s84a642\",\"npub1ljm9zuj2k4d0lsgnpl2vh0rwtls7yrptpxu9js0v7y9hfplncnksn38rxz\",\"npub1vl4hymmmhr33vsvv63k059cdtqp5teg6m0qcd78h4gx58qzhjdgq7cs9rd\",\"npub1vchehlucehyyesu4tzdwu5u2sf5n8wqyhem2u6mg94v7rztq76eqsrzfru\",\"npub1vx0v2x8m6vepn7rn0umfks6kghu7hmjzdwtlxtcskzwj56whukrs3h95tl\",\"npub1gsyvqrq7jdvvqkk3rklz6wsaft9cc2md6cuxun3a48s5hvrd7s4sgeqd9m\",\"npub1xnm7sj22xapljxxp48kh2m2jcdndd4yy87k22yv709tnz3s9ycrq4juctl\"],\"sub_tags\":[\"TRAVEL\",\"Travelling\",\"Camps\",\"Airports\",\"Airplanes\",\"Trailer\",\"Camping\",\"Camping Car\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/social.png\",\"main_tag\":\"Social\",\"onboarding\":true,\"pubkeys\":[\"npub1uw6lgv5qyexx68fwgdmwt3w7v3dwv679sray2ncpkug70ad7a8gqut3tay\",\"npub1wmr34t36fy03m8hvgl96zl3znndyzyaqhwmwdtshwmtkg03fetaqhjg240\",\"npub1mt8x8vqvgtnwq97sphgep2fjswrqqtl4j7uyr667lyw7fuwwsjgs5mm7cz\",\"npub1mt8x8vqvgtnwq97sphgep2fjswrqqtl4j7uyr667lyw7fuwwsjgs5mm7cz\",\"npub1jk9h2jsa8hjmtm9qlcca942473gnyhuynz5rmgve0dlu6hpeazxqc3lqz7\",\"npub18ams6ewn5aj2n3wt2qawzglx9mr4nzksxhvrdc4gzrecw7n5tvjqctp424\",\"npub1vyrx2prp0mne8pczrcvv38ahn5wahsl8hlceeu3f3aqyvmu8zh5s7kfy55\"],\"sub_tags\":[\"plebs\",\"social platform\",\"plebchain\",\"Social Media\",\"twitter\",\"Twitter\",\"Social Network\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/nostr.png\",\"main_tag\":\"Nostr\",\"onboarding\":true,\"pubkeys\":[\"npub180cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwsyjh6w6\",\"npub1l2vyh47mk2p0qlsku7hg0vn29faehy9hy34ygaclpn66ukqp3afqutajft\",\"npub1l2vyh47mk2p0qlsku7hg0vn29faehy9hy34ygaclpn66ukqp3afqutajft\",\"npub1v0lxxxxutpvrelsksy8cdhgfux9l6a42hsj2qzquu2zk7vc9qnkszrqj49\",\"npub1v0lxxxxutpvrelsksy8cdhgfux9l6a42hsj2qzquu2zk7vc9qnkszrqj49\",\"npub1qqqqqqyz0la2jjl752yv8h7wgs3v098mh9nztd4nr6gynaef6uqqt0n47m\",\"npub1sg6plzptd64u62a878hep2kev88swjh3tw00gjsfl8f237lmu63q0uf63m\"],\"sub_tags\":[\"Nostr\",\"NOSTR\",\"Make NOSTR Better\",\"plebchain\",\"pleb\",\"guide\",\"#plebchain\",\"#pleb\",\"zaps\",\"artonnostr\",\"Decentralization\",\"#nostr\",\"lightning\",\"NostrTechWeekly\",\"NostReport\",\"Lightning Network\",\"minibolt\",\"Open Source\",\"SATs\",\"zap\",\"Zap\",\"Make nostr Better\",\"Make Nostr Better\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/writing.png\",\"main_tag\":\"Writing\",\"onboarding\":true,\"pubkeys\":[\"npub1jmy8weweqzckna0amz7pn0uhhkxx693l7st23829ewmu43yvjsesfp6xcq\",\"npub1refv24r8vqs73ydfmhc6p86am3ll85g7t3redygtlukczgthryyq929579\",\"npub1puufhwjns4742aqz5nv8e7pedszx0678muve9xxue8sd9xelzj8s8k5f6e\",\"npub1htg06l09dcjqqfhl55hhtnzp3yd4klv7dm8w64egygmcr7pswz2sr32fuc\",\"npub127dx78padn03hvkslywlw0am9agw7e6xrfnq99chg5c4cduqlves6smdwd\",\"npub1cdak4q4f3h3k3sgyh0rd5dj4w8k95f3mquzh6z3ew76vqkh60e3slyczgz\",\"npub192klhzk86sav5mgkfmveyjq50ygqfqnfvq0lvr2yv0zdtvatlhxskg43u7\"],\"sub_tags\":[\"Writing\",\"writing\",\"blogging\",\"poetry\",\"literature\",\"#literature\",\"poem\",\"#poem\",\"author\",\"poetstr\",\"sonnet\",\"#sonnet\",\"#author\",\"#poetry \",\"poemstr\",\"#poemstr\",\"#poet\",\"#poetstr\",\"#artonnostr\",\"original\",\"#original\",\"poet\",\"gita\",\"mahabharata\",\"gita.shutri.com\"]},{\"icon\":\"https://yakihonne.s3.ap-east-1.amazonaws.com/categories_imgs/food.png\",\"main_tag\":\"Food\",\"onboarding\":true,\"pubkeys\":[\"npub1n0pdxnwa4q7eg2slm5m2wjrln2hvwsxmyn48juedjr3c85va99yqc5pfp6\",\"npub1k0jrarx8um0lyw3nmysn50539ky4k8p7gfgzgrsvn8d7lccx3d0s38dczd\",\"npub1uz5vh467hljwlwag5e0l2ja5xkzcgp8kms96ffj93gjd0ajz692qv3ucfc\",\"npub19xgymswuxyq4sx58enft9c6algrm72a6lchplm4rjzgklufn9ygq5kcu58\",\"npub1tw893tsr9k6h52l473sfrr9wce8yn8rkl7tswleg4ku7su2lpkmqn28ty5\",\"npub15u3cqhx6vuj3rywg0ph5mfv009lxja6cyvqn2jagaydukq6zmjwqex05rq\",\"npub10us6l7kvn340s2mw4jhluj0jlpt3zthnqftk8xewy80d64lpj96qa7xew6\"],\"sub_tags\":[\"Food\",\"Cooking\",\"nostrcooking\",\"#keto\",\"#low carb\",\"nostrcooking-sauce\",\"Vegetarian\",\"nostrcooking-breakfast\",\"nostrcooking-alcohol\",\"nostrcooking-american\",\"nutrition\",\"Vegetarianism\"]}]";

  static List<InterestSet> getInterestSets() {
    try {
      final list = jsonDecode(st) as List<dynamic>;

      return list
          .map<InterestSet>(
            (e) => InterestSet.fromMap(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  factory InterestSet.fromMap(Map<String, dynamic> map) {
    return InterestSet(
      interest: map['main_tag'] as String,
      image: map['icon'] as String,
      onboarding: map['onboarding'] as bool,
      pubkeys: Set<String>.from(map['pubkeys'] as List)
          .map(
            (e) => Nip19.decodePubkey(e),
          )
          .toSet(),
      subInterests: List<String>.from(map['sub_tags'] as List),
    );
  }
}
