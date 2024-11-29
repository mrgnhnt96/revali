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
    ReadOnlyDataHandler data,
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

  InterceptorPreResult getMetaDataForRole() {}

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
    ReadOnlyDataHandler context,
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
  FutureOr<User> transform(String value, PipeContext context) {
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
