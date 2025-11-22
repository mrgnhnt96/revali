import 'package:revali_router/revali_router.dart';
import 'package:revali_server_meta_reflect_test/domain/access.dart';
import 'package:revali_server_meta_reflect_test/domain/user.dart';

class UserJsonSanitizer implements LifecycleComponent {
  const UserJsonSanitizer();

  InterceptorPostResult sanitize(Response response, Reflect reflect) {
    final reflector = reflect.get<User>();

    final body = response.body.data;
    if (body case {'data': final Map<String, dynamic> data}) {
      final json = {...data};
      for (final key in data.keys) {
        final meta = reflector?.get(key);
        final access = meta?.get<Access>();

        if (access?.any((e) => e.type == AccessType.private) ?? false) {
          json.remove(key);
        }
      }

      response.body = {'data': json};
    }
  }
}
