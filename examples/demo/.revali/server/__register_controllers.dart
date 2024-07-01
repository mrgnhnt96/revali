part of '../server.dart';

void _registerControllers() {
  DI.instance.registerLazySingleton<ThisController>(
      () => ThisController(DI.instance.get(), DI.instance.get()));
}
