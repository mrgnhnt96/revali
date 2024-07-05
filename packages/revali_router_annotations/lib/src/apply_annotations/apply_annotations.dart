import 'package:revali_router/revali_router.dart';

abstract class ApplyAnnotations {
  const ApplyAnnotations();

  List<Guard> guards() => const [];
  List<Middleware> middleware() => const [];
  List<Interceptor> interceptors() => const [];
  List<ExceptionCatcher> catchers() => const [];
  List<Data> data() => const [];
}
