part of '../server.dart';

List<Route> routes(DI di) => [
      user(
        ThisController(
          logger: di.get(),
          repo: di.get(),
        ),
        di,
      ),
      some(
        Some(),
        di,
      ),
      file(
        FileUploader(),
        di,
      ),
    ];
