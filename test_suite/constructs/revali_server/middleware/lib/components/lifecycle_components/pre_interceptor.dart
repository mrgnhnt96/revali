import 'package:revali_router/revali_router.dart';
import 'package:revali_server_middleware_test/domain/auth_token.dart';

// Learn more about Lifecycle Components at https://www.revali.dev/constructs/revali_server/lifecycle-components/components
class AddData implements LifecycleComponent {
  const AddData();

  InterceptorPreResult addData(DataHandler data) {
    data
      ..add('loz')
      ..add(const AuthToken('loz'));
  }
}

class SomeLogger implements LifecycleComponent {
  const SomeLogger(
    this.logger, {
    this.fallback,
  });

  final Logger logger;
  final Logger? fallback;

  InterceptorPreResult addData(DataHandler data) {
    data.add('loz');
  }
}

class Logger {
  const Logger();
}

class AddCustomData<T extends Object> implements LifecycleComponent {
  const AddCustomData(this.data);

  final T data;

  InterceptorPreResult addData(DataHandler data) {
    data.add(this.data);
  }
}
