import 'package:revali_router/revali_router.dart';

class AddCookies implements LifecycleComponent {
  const AddCookies();

  MiddlewareResult addAuth(MutableSetCookies cookies) {
    cookies['X-Auth-Middleware'] = '123';

    return const MiddlewareResult.next();
  }

  InterceptorPreResult addAuthPre(MutableSetCookies cookies) {
    cookies['X-Auth-Pre'] = '456';
  }

  InterceptorPostResult addAuthPost(MutableSetCookies cookies) {
    cookies['X-Auth-Post'] = '789';
  }
}
