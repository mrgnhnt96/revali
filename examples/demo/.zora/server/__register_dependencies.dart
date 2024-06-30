part of '../server.dart';

void _registerDependencies() {
  DI.instance.registerLazySingleton(Repo.new);
  DI.instance.registerLazySingleton(Logger.new);
}
