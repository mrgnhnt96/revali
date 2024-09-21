part of '../server.dart';

List<Route> routes(DI di) => [
      hello(
        HelloController(),
        di,
      )
    ];
