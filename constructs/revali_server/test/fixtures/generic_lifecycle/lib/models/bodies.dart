class UserBody {
  const UserBody({required this.id});

  factory UserBody.fromJson(Map<String, dynamic> json) {
    return UserBody(id: json['id'] as String);
  }

  final String id;
}

class OrderBody {
  const OrderBody({required this.total});

  factory OrderBody.fromJson(Map<String, dynamic> json) {
    return OrderBody(total: json['total'] as int);
  }

  final int total;
}
