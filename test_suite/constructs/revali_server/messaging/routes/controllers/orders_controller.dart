import 'package:revali_router/revali_router.dart';

@Controller('orders')
class OrdersController {
  const OrdersController();

  /// Everything each consumer saw, for the tests to assert on.
  static final seen = <String, List<BrokerMessage>>{};

  /// Request ids observed inside handlers, to prove trace continuity.
  static final traces = <String?>[];

  @Get()
  String list() => 'ok';

  @Consumes('order.placed', group: 'billing')
  Future<void> onPlaced(BrokerMessage message) async {
    (seen['billing'] ??= []).add(message);
    traces.add(TraceContext.current?.requestId);
  }

  /// A second group on the same topic: both must get a copy.
  @Consumes('order.placed', group: 'shipping')
  void alsoOnPlaced(BrokerMessage message) {
    (seen['shipping'] ??= []).add(message);
  }

  /// A handler that takes no parameters at all.
  @Consumes('order.cancelled', group: 'billing')
  void onCancelled() {
    (seen['cancelled'] ??= []).add(
      const BrokerMessage(topic: 'order.cancelled', id: '-', payload: ''),
    );
  }
}
