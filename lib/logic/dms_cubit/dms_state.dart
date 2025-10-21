// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'dms_cubit.dart';

class DmsState extends Equatable {
  final Map<String, DMSessionDetail> dmSessionDetails;
  final bool isUsingNip44;
  final int index;
  final bool rebuild;
  final List<String> mutes;
  final bool isSendingMessage;
  final int selectedTime;
  final bool isLoadingHistory;
  final DmDataState dmDataState;

  const DmsState({
    required this.dmSessionDetails,
    required this.isUsingNip44,
    required this.index,
    required this.rebuild,
    required this.mutes,
    required this.isSendingMessage,
    required this.selectedTime,
    required this.isLoadingHistory,
    required this.dmDataState,
  });

  @override
  List<Object> get props => [
        dmSessionDetails,
        index,
        isUsingNip44,
        rebuild,
        mutes,
        isSendingMessage,
        selectedTime,
        isLoadingHistory,
        dmDataState,
      ];

  DmsState copyWith({
    Map<String, DMSessionDetail>? dmSessionDetails,
    bool? isUsingNip44,
    int? index,
    bool? rebuild,
    List<String>? mutes,
    bool? isSendingMessage,
    int? selectedTime,
    bool? isLoadingHistory,
    DmDataState? dmDataState,
  }) {
    return DmsState(
      dmSessionDetails: dmSessionDetails ?? this.dmSessionDetails,
      isUsingNip44: isUsingNip44 ?? this.isUsingNip44,
      index: index ?? this.index,
      rebuild: rebuild ?? this.rebuild,
      mutes: mutes ?? this.mutes,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      selectedTime: selectedTime ?? this.selectedTime,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      dmDataState: dmDataState ?? this.dmDataState,
    );
  }
}
