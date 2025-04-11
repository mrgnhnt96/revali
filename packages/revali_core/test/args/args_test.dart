import 'package:revali_core/args/args.dart';
import 'package:test/test.dart';

void main() {
  group(Args, () {
    group('#parse', () {
      test('should parse values', () {
        final args = Args.parse(['--flag']);

        expect(args.values, {'flag': true});
      });

      test('should parse negated values', () {
        final args = Args.parse(['--no-flag']);

        expect(args.values, {'flag': false});
      });

      test('should parse options using =', () {
        final args = Args.parse(['--key=value']);

        expect(args.values, {'key': 'value'});
      });

      test('should parse options as separate arguments', () {
        final args = Args.parse(['--key', 'value']);

        expect(args.values, {'key': 'value'});
      });

      test('should parse multi options with values', () {
        final args = Args.parse(['--key=value1', '--key', 'value2']);

        expect(args.values, {
          'key': ['value1', 'value2'],
        });
      });

      test('should parse rest', () {
        final args = Args.parse(['--key=value', 'rest1', 'rest2']);

        expect(args.rest, ['rest1', 'rest2']);
      });

      test('should remove double quotes from values', () {
        final args = Args.parse(['--key="value"']);

        expect(args.values, {'key': 'value'});
      });

      test('should remove single quotes from values', () {
        final args = Args.parse(["--key='value'"]);

        expect(args.values, {'key': 'value'});
      });
    });
  });
}
