import 'dart:async';

class Debouncer<T> extends StreamTransformerBase<T, T> {
  const Debouncer([this.duration = const Duration(milliseconds: 300)]);

  @override
  Stream<T> bind(Stream<T> stream) {
    final controller = StreamController<T>();
    var hasEmitFirstEvent = false;
    Timer? timer;

    final subscription = stream.listen((event) {
      timer?.cancel();

      if (!hasEmitFirstEvent) {
        controller.add(event);
        hasEmitFirstEvent = true;
        timer = Timer(duration, () {
          hasEmitFirstEvent = false;
        });
        return;
      }

      timer = Timer(duration, () {
        controller.add(event);
        hasEmitFirstEvent = false;
      });
    });

    controller.onCancel = () {
      subscription.cancel();
      timer?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  final Duration duration;

  @override
  StreamTransformer<RS, RT> cast<RS, RT>() {
    throw UnimplementedError();
  }
}
