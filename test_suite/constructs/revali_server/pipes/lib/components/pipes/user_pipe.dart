import 'dart:async';

import 'package:revali_router/revali_router.dart';
import 'package:revali_server_pipes_test/domain/user.dart';

// Learn more about Pipes at https://www.revali.dev/constructs/revali_server/core/pipes
class UserPipe implements Pipe<String, User> {
  const UserPipe();

  @override
  Future<User> transform(String value, PipeContext context) async {
    return User(value);
  }
}
