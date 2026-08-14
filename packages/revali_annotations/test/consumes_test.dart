import 'package:revali_annotations/revali_annotations.dart';
import 'package:test/test.dart';

void main() {
  group('Consumes', () {
    test('carries its topic and group', () {
      const annotation = Consumes('order.placed', group: 'billing');

      expect(annotation.topic, 'order.placed');
      expect(annotation.group, 'billing');
    });

    test('is const, so it can annotate', () {
      // An annotation has to be a compile-time constant; this would not
      // compile if the constructor stopped being const.
      const first = Consumes('t', group: 'g');
      const second = Consumes('t', group: 'g');

      expect(identical(first, second), isTrue);
    });
  });
}
