import 'package:revali_server_meta_reflect_test/domain/access.dart';

class User {
  const User({required this.password, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      password: json['password'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'password': password, 'name': name};
  }

  final String name;

  @Access(AccessType.private)
  final String password;

  @override
  String toString() {
    return 'User(password: $password, name: $name)';
  }
}
