class User {
  const User({
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {};
  }

  final String name;
}
