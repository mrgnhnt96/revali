import 'package:revali_router/revali_router.dart';

// Learn more about Lifecycle Components at https://www.revali.dev/constructs/revali_server/lifecycle-components/components
class AddData implements LifecycleComponent {
  const AddData();

  InterceptorPreResult addData(DataHandler data) {
    data.add('loz');
  }
}

class AddCustomData<T> implements LifecycleComponent {
  const AddCustomData(this.data);

  final T data;

  InterceptorPreResult addData(DataHandler data) {
    data.add(this.data);
  }
}
