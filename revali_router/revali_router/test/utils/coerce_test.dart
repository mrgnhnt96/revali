import 'package:revali_router/utils/coerce.dart';
import 'package:test/test.dart';

void main() {
  group('coerce', () {
    test('should coerce a string to an int', () {
      expect(coerce('1'), 1);
    });

    test('should coerce a string to a double', () {
      expect(coerce('1.1'), 1.1);
    });

    test('should coerce a string to a list', () {
      expect(coerce('["hello", "2", "true"]'), ['hello', 2, true]);
    });

    test('should coerce a string to a list of dynamic', () {
      expect(coerce('[1, 2]'), [1, 2]);
    });

    test('should coerce a string to a map of dynamic', () {
      expect(coerce('{"a": 1, "b": 2}'), {'a': 1, 'b': 2});
    });

    test('should coerce a string to a boolean', () {
      expect(coerce('true'), true);
      expect(coerce('false'), false);
    });

    test('should return the original value if no coercion is possible', () {
      expect(coerce('foo'), 'foo');
    });
  });
}
