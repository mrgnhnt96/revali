import 'package:hello/custom_params/get_user.dart';
import 'package:revali_router/revali_router.dart';

class AuthGuard implements Guard {
  const AuthGuard();

  @override
  Future<GuardResult> protect(Context context) async {
    print('Auth guard');
    return const GuardResult.pass();
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
  List<Middleware> get middlewares => [AuthMiddleware()];
}

class AuthMiddleware implements Middleware {
  @override
  Future<MiddlewareResult> use(Context context) async {
    context.data.add(const User());

    return const MiddlewareResult.next();
  }
}
