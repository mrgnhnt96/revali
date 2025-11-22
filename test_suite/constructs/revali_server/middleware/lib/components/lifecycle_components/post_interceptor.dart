import 'package:revali_router/revali_router.dart';

// Learn more about Lifecycle Components at https://www.revali.dev/constructs/revali_server/lifecycle-components/components
class AddHeader implements LifecycleComponent {
  const AddHeader();

  InterceptorPostResult postInterceptor(Headers headers) {
    headers.add('X-Middleware', 'loz');
  }
}

class AddCustomHeader implements LifecycleComponent {
  const AddCustomHeader({required this.key, required this.value});

  final String key;
  final String value;

  InterceptorPostResult postInterceptor(Headers headers) {
    headers.add(key, value);
  }
}
