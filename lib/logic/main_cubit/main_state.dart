// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'main_cubit.dart';

class MainState extends Equatable {
  final MainViews mainView;
  final bool refresh;
  final String image;
  final String random;
  final String name;
  final String nip05;
  final String pubKey;
  final bool isMyContentShrinked;
  final bool isCashuWallet;
  final bool isHorizontal;
  final bool isConnected;

  const MainState({
    required this.mainView,
    required this.refresh,
    required this.image,
    required this.random,
    required this.name,
    required this.nip05,
    required this.pubKey,
    required this.isMyContentShrinked,
    required this.isCashuWallet,
    required this.isHorizontal,
    required this.isConnected,
  });

  @override
  List<Object> get props => [
        mainView,
        refresh,
        random,
        image,
        name,
        nip05,
        pubKey,
        isMyContentShrinked,
        isCashuWallet,
        isHorizontal,
        isConnected,
      ];

  MainState copyWith({
    MainViews? mainView,
    bool? refresh,
    String? image,
    String? random,
    String? name,
    String? nip05,
    String? pubKey,
    bool? isMyContentShrinked,
    bool? isCashuWallet,
    bool? isHorizontal,
    bool? isConnected,
  }) {
    return MainState(
      mainView: mainView ?? this.mainView,
      refresh: refresh ?? this.refresh,
      image: image ?? this.image,
      random: random ?? this.random,
      name: name ?? this.name,
      nip05: nip05 ?? this.nip05,
      pubKey: pubKey ?? this.pubKey,
      isMyContentShrinked: isMyContentShrinked ?? this.isMyContentShrinked,
      isCashuWallet: isCashuWallet ?? this.isCashuWallet,
      isHorizontal: isHorizontal ?? this.isHorizontal,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
