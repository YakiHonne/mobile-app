import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class FilterStatus {
  bool leadingFilter;
  bool discoverFilter;

  FilterStatus({
    required this.leadingFilter,
    required this.discoverFilter,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'leadingFilter': leadingFilter,
      'discoverFilter': discoverFilter,
    };
  }

  factory FilterStatus.fromMap(Map<String, dynamic> map) {
    return FilterStatus(
      leadingFilter: map['leadingFilter'] as bool,
      discoverFilter: map['discoverFilter'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory FilterStatus.fromJson(String source) =>
      FilterStatus.fromMap(json.decode(source) as Map<String, dynamic>);
}
