// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'relay_feed_cubit.dart';

class RelayFeedState extends Equatable {
  final List<BaseEventModel> content;
  final List<RelayReview> reviews;
  final bool onLoadingReviews;
  final bool onLoading;
  final UpdatingState onAddingData;
  final bool refresh;
  final bool isNip43Supported;
  final bool isMember;
  final bool checkMembership;

  const RelayFeedState({
    required this.content,
    required this.reviews,
    required this.onLoadingReviews,
    required this.onLoading,
    required this.onAddingData,
    required this.refresh,
    this.isNip43Supported = false,
    this.isMember = false,
    this.checkMembership = false,
  });

  @override
  List<Object> get props => [
        content,
        reviews,
        onLoadingReviews,
        onLoading,
        onAddingData,
        refresh,
        isNip43Supported,
        isMember,
        checkMembership,
      ];

  RelayFeedState copyWith({
    List<BaseEventModel>? content,
    List<RelayReview>? reviews,
    bool? onLoadingReviews,
    bool? onLoading,
    UpdatingState? onAddingData,
    bool? refresh,
    bool? isNip43Supported,
    bool? isMember,
    bool? checkMembership,
  }) {
    return RelayFeedState(
      content: content ?? this.content,
      reviews: reviews ?? this.reviews,
      onLoadingReviews: onLoadingReviews ?? this.onLoadingReviews,
      onLoading: onLoading ?? this.onLoading,
      onAddingData: onAddingData ?? this.onAddingData,
      refresh: refresh ?? this.refresh,
      isNip43Supported: isNip43Supported ?? this.isNip43Supported,
      isMember: isMember ?? this.isMember,
      checkMembership: checkMembership ?? this.checkMembership,
    );
  }
}
