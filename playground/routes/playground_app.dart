import 'package:revali_router/revali_router.dart';

@App(flavor: 'dev')
final class PlaygroundApp extends AppConfig {
  const PlaygroundApp() : super(host: 'localhost', port: 8090);
}
