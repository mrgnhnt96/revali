part of '../server.dart';

void _registerControllers() {
  DI.instance.registerLazySingleton<user_controller.ThisController>(() =>
      user_controller.ThisController(DI.instance.get(), DI.instance.get()));
}
