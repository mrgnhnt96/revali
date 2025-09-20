class User {
  const User({required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'name': name};
  }

  final String name;

  @override
  String toString() {
    return 'User(name: $name)';
  }
}
