import 'package:revali_router/revali_router.dart';

/// Endpoints shared by several controllers.
abstract class CrudBase {
  const CrudBase();

  @Get('all')
  List<String> findAll() => const [];

  @Delete('purge')
  String purge() => 'purged';
}

mixin HealthEndpoints {
  @Get('health')
  String health() => 'ok';
}

@Controller('inherited')
class InheritedController extends CrudBase with HealthEndpoints {
  const InheritedController();

  @Post('')
  String create() => 'created';
}

@Controller('overriding')
class OverridingController extends CrudBase {
  const OverridingController();

  /// Same Dart method, different route: the subclass must win, and the base
  /// annotation must not also register.
  @override
  @Get('everything')
  List<String> findAll() => const ['a'];
}

@Controller('inheriting-unannotated')
class UnannotatedOverrideController extends CrudBase {
  const UnannotatedOverrideController();

  /// Overrides the implementation but not the annotation, so the route comes
  /// from the base and dispatches here at runtime.
  @override
  List<String> findAll() => const ['b'];
}
