// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'add_content_cubit.dart';

class AddContentState extends Equatable {
  final bool displayBottomNavigationBar;
  final AppContentType appContentType;

  const AddContentState({
    required this.displayBottomNavigationBar,
    required this.appContentType,
  });

  @override
  List<Object> get props => [
        displayBottomNavigationBar,
        appContentType,
      ];

  AddContentState copyWith({
    bool? displayBottomNavigationBar,
    AppContentType? appContentType,
  }) {
    return AddContentState(
      displayBottomNavigationBar:
          displayBottomNavigationBar ?? this.displayBottomNavigationBar,
      appContentType: appContentType ?? this.appContentType,
    );
  }
}
