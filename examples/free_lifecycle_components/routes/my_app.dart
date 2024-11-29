import 'package:revali_router/revali_router.dart';

@App(flavor: 'dev')
final class MyApp extends AppConfig {
  const MyApp() : super(host: 'localhost', port: 8083);
}
