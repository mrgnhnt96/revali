import 'dart:async';

import 'package:revali_router/src/body/body_impl.dart';
import 'package:revali_router/src/body/response_body/base_body_data.dart';
import 'package:test/test.dart';

void main() {
  group(BodyImpl, () {
    test(
      'read() cancels the underlying subscription instead of leaving it '
      'paused when its listener cancels',
      () async {
        var canceled = false;
        final controller = StreamController<List<int>>(
          onCancel: () => canceled = true,
        );

        final body = BodyImpl(StreamBodyData(controller.stream));

        final subscription = body.read()!.listen((_) {});
        // Let the async* generator actually subscribe to the broadcast
        // stream before canceling, or there is nothing to cancel yet.
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        expect(canceled, isTrue);
      },
    );
  });
}
