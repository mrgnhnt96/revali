import 'package:revali_construct/enums/generate_construct_type.dart';
import 'package:test/test.dart';

void main() {
  group(GenerateConstructType, () {
    test('is exactly the two phases, with no combined value', () {
      expect(GenerateConstructType.values, [
        GenerateConstructType.build,
        GenerateConstructType.constructs,
      ]);
    });

    test('no value reports both phases', () {
      // `_generateIntoStaging` branches `if (isBuild) { build makers } else
      // { server + other makers }`. A value answering true to both takes the
      // build branch and silently skips every construct — which is exactly
      // what `buildAndConstructs` did, and why `revali build` never
      // regenerated the client. Running both phases is the caller's job.
      for (final type in GenerateConstructType.values) {
        expect(
          type.isBuild && type.isConstructs,
          isFalse,
          reason: '$type claims to be both phases',
        );
      }
    });

    test('every value is one phase or the other', () {
      for (final type in GenerateConstructType.values) {
        expect(
          type.isBuild || type.isConstructs,
          isTrue,
          reason: '$type is neither phase',
        );
      }
    });

    test('the negated getters mirror their positives', () {
      for (final type in GenerateConstructType.values) {
        expect(type.isNotBuild, !type.isBuild, reason: '$type');
        expect(type.isNotConstructs, !type.isConstructs, reason: '$type');
      }
    });

    test('every value describes itself', () {
      for (final type in GenerateConstructType.values) {
        expect(type.description, isNotEmpty, reason: '$type');
      }
    });
  });
}
