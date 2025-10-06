// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'share_content_cubit.dart';

class ShareContentState extends Equatable {
  final bool isSendingToFollowings;
  final Color selectedQrColor;
  final Set<String> availablePubkeys;
  final Map<String, ShareContentUserStatus> processedPubkeys;
  final bool isSending;
  final bool hasFinished;

  const ShareContentState({
    required this.isSendingToFollowings,
    required this.selectedQrColor,
    required this.availablePubkeys,
    required this.processedPubkeys,
    required this.isSending,
    required this.hasFinished,
  });

  @override
  List<Object> get props => [
        isSendingToFollowings,
        selectedQrColor,
        availablePubkeys,
        processedPubkeys,
        isSending,
        hasFinished,
      ];

  ShareContentState copyWith({
    bool? isSendingToFollowings,
    Color? selectedQrColor,
    Set<String>? availablePubkeys,
    Map<String, ShareContentUserStatus>? processedPubkeys,
    bool? isSending,
    bool? hasFinished,
  }) {
    return ShareContentState(
      isSendingToFollowings:
          isSendingToFollowings ?? this.isSendingToFollowings,
      selectedQrColor: selectedQrColor ?? this.selectedQrColor,
      availablePubkeys: availablePubkeys ?? this.availablePubkeys,
      processedPubkeys: processedPubkeys ?? this.processedPubkeys,
      isSending: isSending ?? this.isSending,
      hasFinished: hasFinished ?? this.hasFinished,
    );
  }
}
