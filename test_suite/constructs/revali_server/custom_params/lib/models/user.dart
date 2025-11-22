class User {
  const User({required this.name});

  // ignore: prefer_constructors_over_static_methods
  static User fromJson(Map<String, String> json) {
    return User(name: json['name']!);
  }

  final String name;

  Map<String, dynamic> toJson() {
    return {'name': name};
  }
}
