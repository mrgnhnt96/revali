// ignore_for_file: unnecessary_lambdas

import 'dart:async';

import 'package:client/client.dart';
import 'package:client_gen_models/client_gen_models.dart';

void main() async {
  final server = Server();

  await server.auth.login(
    email: 'email',
    password: 'password',
  );

  final stream = server.game.handle(
    user: sendUsers(),
  );

  final listener = stream.listen(
    (user) {
      print(user);
    },
    cancelOnError: true,
    onDone: () {
      print('done!');
    },
    onError: (Object e) {
      print('An error occurred: $e');
    },
  );

  await listener.asFuture<void>();

  listener.cancel().ignore();
}

Stream<User> sendUsers() async* {
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(const Duration(seconds: 5));
    print('sending!');
    yield User(
      name: 'name$i',
    );
  }
}
