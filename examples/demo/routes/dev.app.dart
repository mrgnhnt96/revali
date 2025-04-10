import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:revali_router/revali_router.dart';

@AllowOrigins.all()
@AllowHeaders({'X-IM-AWESOME'})
@App(flavor: 'dev')
final class DevApp extends AppConfig {
  DevApp()
      : super(
          host: 'localhost',
          port: 8080,
        );

  @override
  Future<void> configureDependencies(DI di) async {
    di
      ..registerLazySingleton(Repo.new)
      ..registerLazySingleton(Logger.new);
  }
}
