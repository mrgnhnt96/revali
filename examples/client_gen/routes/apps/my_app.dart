import 'package:revali_router/revali_router.dart';

// Learn more about Apps at https://www.revali.dev/revali/app-configuration/overview
@App(flavor: 'my')
final class MyApp extends AppConfig {
  const MyApp()
      : super(
          host: 'localhost',
          port: 8080,
          prefix: 'aloha',
        );
}
