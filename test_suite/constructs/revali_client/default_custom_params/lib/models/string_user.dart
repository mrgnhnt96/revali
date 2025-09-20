import 'package:equatable/equatable.dart';

class StringUser extends Equatable {
  const StringUser({required this.name});

  factory StringUser.fromJson(String json) {
    return StringUser(name: json);
  }

  final String name;

  String toJson() {
    return name;
  }

  @override
  List<Object?> get props => [name];
}
