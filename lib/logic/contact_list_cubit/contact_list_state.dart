part of 'contact_list_cubit.dart';

class ContactListState extends Equatable {
  const ContactListState({
    required this.refresh,
  });

  final bool refresh;

  @override
  List<Object> get props => [refresh];

  ContactListState copyWith({
    bool? refresh,
  }) {
    return ContactListState(
      refresh: refresh ?? this.refresh,
    );
  }
}
