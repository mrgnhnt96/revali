import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

import '../.revali/server/server.dart';
import '../routes/apps/test_app.dart';
import '../routes/controllers/orders_controller.dart';

void main() {
  group('@Consumes on a generated server', () {
    late TestServer server;

    setUp(() async {
      OrdersController.seen.clear();
      OrdersController.traces.clear();
      TestBroker.enabled = true;
      TestBroker.instance = null;

      server = TestServer();
      await createServer(server);
    });

    tearDown(() => server.close());

    test('subscribes the annotated handler', () async {
      await TestBroker.instance!.publish('order.placed', 'placed');

      expect(OrdersController.seen['billing']?.single.payload, 'placed');
    });

    test('gives each group its own copy', () async {
      await TestBroker.instance!.publish('order.placed', 'placed');

      // Two @Consumes on one topic with different groups: both fire.
      expect(OrdersController.seen['billing'], hasLength(1));
      expect(OrdersController.seen['shipping'], hasLength(1));
    });

    test('supports a handler that takes no parameters', () async {
      await TestBroker.instance!.publish('order.cancelled', 'gone');

      expect(OrdersController.seen['cancelled'], hasLength(1));
    });

    test('does not deliver a topic nobody consumes', () async {
      await TestBroker.instance!.publish('order.refunded', 'refunded');

      expect(OrdersController.seen, isEmpty);
    });

    test('runs the handler inside a trace context', () async {
      await TestBroker.instance!.publish(
        'order.placed',
        'placed',
        headers: {'X-Request-Id': 'from-the-request'},
      );

      // The whole point of wiring consumers through the framework rather than
      // subscribing by hand.
      expect(OrdersController.traces.single, 'from-the-request');
    });

    test('leaves ordinary routes working', () async {
      final response = await server.send(method: 'GET', path: '/api/orders');

      expect(response.statusCode, 200);
      expect(response.body, {'data': 'ok'});
    });
  });

  group('without a broker', () {
    test('registers nothing at all', () async {
      OrdersController.seen.clear();
      TestBroker.enabled = false;
      TestBroker.instance = null;

      final server = TestServer();
      await createServer(server);
      addTearDown(server.close);

      // Messaging is opt-in: annotated handlers exist, but an app that
      // supplies no broker subscribes to nothing.
      expect(TestBroker.instance, isNull);
      expect(OrdersController.seen, isEmpty);
    });
  });
}
