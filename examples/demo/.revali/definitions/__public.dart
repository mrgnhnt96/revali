part of '../server.dart';

List<Route> get public => [
      Route(
        'favicon.png',
        method: 'GET',
        allowedOrigins: AllowOrigins.all(),
        handler: (context) async {
          context.response.body = File(p.join(
            'public',
            'favicon.png',
          ));
        },
      )
    ];
