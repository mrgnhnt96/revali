import 'package:revali_router/revali_router.dart';

// Learn more about Apps at https://docs.revali.dev/revali/app-configuration/
@App(flavor: 'my')
final class MyApp extends AppConfig {
  const MyApp()
      : super(
          host: 'localhost',
          port: 7069,
          prefix: 'aloha',
        );
}
