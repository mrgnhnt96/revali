import 'package:revali_router/revali_router.dart';

class AuthGuard implements Guard {
  const AuthGuard();

  @override
  Future<GuardResult> canActivate(
    GuardContext context,
    GuardAction action,
  ) async {
    print('Auth guard');
    return action.yes();
  }
}

final class AuthComponents implements CombineComponents {
  const AuthComponents();

  @override
  List<ExceptionCatcher<Exception>> get catchers => [];

  @override
  List<Guard> get guards => [const AuthGuard()];

  @override
  List<Interceptor> get interceptors => [];

  @override
  List<Middleware> get middlewares => [];
}
