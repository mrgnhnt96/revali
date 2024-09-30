import 'dart:async';

import 'package:revali_router/revali_router.dart';

class User {
  const User();
}

class UserService {
  const UserService();

  Future<User> getUser() async {
    return const User();
  }
}

class GetUser implements Bind<User> {
  const GetUser(this._userService);

  final UserService _userService;

  @override
  FutureOr<User> bind(BindContext context) {
    return _userService.getUser();
  }
}
