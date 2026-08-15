import 'package:revali_router/revali_router.dart';

@Controller('work')
class WorkController {
  const WorkController();

  @Get()
  String ping() => 'ok';

  /// Exists purely to make `hasConsumers` true in the server generator, which
  /// is what gates the emitted `await app.createBroker()` call. Without one
  /// annotated handler somewhere in the app, `createBroker()` is never invoked
  /// and there is nothing to observe.
  @Consumes('work.noop', group: 'noop')
  void onNoop() {}
}
