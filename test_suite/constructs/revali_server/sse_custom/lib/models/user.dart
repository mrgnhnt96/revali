class User {
  const User({required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(name: json['name'] as String);
  }

  final String name;

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
