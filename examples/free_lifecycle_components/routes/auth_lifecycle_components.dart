// ignore_for_file: unnecessary_lambdas

import 'dart:async';

import 'package:revali_router/revali_router.dart';

/*
We can have multiple results of the same type, we can iterate over them
until we get a fail result, then we can stop the iteration
and return the fail result.
 */
class AuthLifecycleComponent implements LifecycleComponent {
  const AuthLifecycleComponent({
    this.role = 'role',
  });

  final String role;

  GuardResult hasToken() {
    return const GuardResult.pass();
  }

  Future<GuardResult> hasRole(
    ReadOnlyData data,
  ) async {
    return const GuardResult.pass();
  }

  Future<GuardResult> fail() async {
    return const GuardResult.block();
  }

  MiddlewareResult addToken() {
    return const MiddlewareResult.next();
  }

  Future<MiddlewareResult> addRole() async {
    return const MiddlewareResult.next();
  }

  InterceptorPreResult getDataOnToken() {}

  Future<InterceptorPreResult> getMetaDataForRole() async {}

  InterceptorPostResult updateMetaDataOnRole() async {}

  InterceptorPostResult someOtherOp(
    @Body(['id'], UserPipe) User pipe,
  ) {}

  ExceptionCatcherResult<MyException> handleFakeTokenException(
    MyException exception,
  ) {
    return const ExceptionCatcherResult.handled();
  }

  ExceptionCatcherResult<OtherException> handleOtherException(
    ReadOnlyData context,
  ) {
    return const ExceptionCatcherResult.handled();
  }

  int something() {
    return 1;
  }

  String hello() {
    return 'hello';
  }
}

class User {
  const User({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class UserPipe implements Pipe<String, User> {
  @override
  Future<User> transform(String value, PipeContext context) async {
    return User(
      id: value,
      name: 'name',
    );
  }
}

class MyException implements Exception {
  const MyException();
}

class OtherException implements Exception {
  const OtherException();
}

class Auth implements LifecycleComponent {
  const Auth();

  Future<MiddlewareResult> getUser({
    @Header() required String authorization,
    required DataHandler dataHandler,
  }) async {
    final userService = UsersService();

    final parts = authorization.split(' ');

    if (parts.length != 2 || parts[0] != 'Bearer') {
      return const MiddlewareResult.stop(
        statusCode: 401,
        body: {'message': 'Invalid authorization header'},
      );
    }

    final token = parts[1];

    dataHandler.add(AuthToken(token));

    final user = await userService.getByToken(token);

    dataHandler.add(user);

    return const MiddlewareResult.next();
  }
}

class UsersService {
  Future<User> getByToken(String token) async {
    return const User(
      id: 'id',
      name: 'name',
    );
  }
}

extension type AuthToken(String token) {}
