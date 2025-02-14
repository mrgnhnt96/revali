import 'dart:async';

import 'package:client_gen_models/client_gen_models.dart';
import 'package:revali_router/revali_router.dart';

// Learn more about Controllers at https://www.revali.dev/constructs/revali_server/core/controllers
@Controller('points')
class PointsController {
  const PointsController();

  @Get('all')
  Stream<List<User>> allPoints() async* {
    final users = <User>[
      const User(name: 'John'),
      const User(name: 'Jane'),
      const User(name: 'Doe'),
    ];

    yield* Stream.fromIterable([users]);
  }

  @Get()
  Stream<User> myPoints() async* {
    final users = <User>[
      const User(name: 'John'),
      const User(name: 'Jane'),
      const User(name: 'Doe'),
    ];

    yield* Stream.fromIterable(users);
  }
}
