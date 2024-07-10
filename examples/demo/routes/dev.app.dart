import 'package:revali_annotations/revali_annotations.dart';

@App(flavor: 'dev')
final class DevApp extends AppConfig {
  DevApp()
      : super(
          host: 'localhost',
          port: 8080,
          onServerStarted: (server) {
            print('Serving at http://${server.address.host}:${server.port}');
          },
        );
}
