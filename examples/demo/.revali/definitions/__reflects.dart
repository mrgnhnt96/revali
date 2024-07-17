part of '../server.dart';

Set<Reflect> get reflects => {
      Reflect(
        User,
        metas: (m) {
          m['id']..add(Role(AuthType.admin));
        },
      )
    };
