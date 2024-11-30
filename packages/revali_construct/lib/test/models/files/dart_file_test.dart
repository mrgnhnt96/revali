import 'package:revali_construct/models/files/dart_file.dart';
import 'package:revali_construct/models/files/part_file.dart';
import 'package:test/test.dart';

final throwsAssertionError = throwsA(isA<AssertionError>());

void main() {
  group(DartFile, () {
    test('should create a DartFile with valid parts', () {
      final part1 = PartFile(path: ['lib', 'src', 'part1'], content: '//');
      final part2 = PartFile(path: ['lib', 'src', 'part2'], content: '//');

      final dartFile = DartFile(
        basename: 'main',
        content: "import 'package:flutter/material.dart';\nvoid main() {}",
        parts: [part1, part2],
      );

      expect(dartFile.parts.length, 2);
      expect(dartFile.parts.contains(part1), isTrue);
      expect(dartFile.parts.contains(part2), isTrue);
    });

    test('should throw an exception for empty part file path', () {
      expect(
        () => DartFile(
          basename: 'main',
          content: 'void main() {}',
          parts: [PartFile(path: [], content: '//')],
        ),
        throwsAssertionError,
      );
    });

    test('should throw an exception for part file path with empty parts', () {
      expect(
        () => DartFile(
          basename: 'main',
          content: 'void main() {}',
          parts: [
            PartFile(path: ['lib', ''], content: '//'),
          ],
        ),
        throwsAssertionError,
      );
    });

    test('should throw an exception for part file path with relative paths',
        () {
      expect(
        () => DartFile(
          basename: 'main',
          content: 'void main() {}',
          parts: [
            PartFile(path: ['lib', '..', 'src'], content: '//'),
          ],
        ),
        throwsAssertionError,
      );
    });

    test('should throw an exception for part file path ending with .dart', () {
      expect(
        () => DartFile(
          basename: 'main',
          content: 'void main() {}',
          parts: [
            PartFile(path: ['lib', 'src', 'part1.dart'], content: '//'),
          ],
        ),
        throwsAssertionError,
      );
    });

    test('should ensure part files are unique within a Dart file', () {
      final part1 = PartFile(path: ['lib', 'src', 'part1'], content: '//');

      expect(
        () => DartFile(
          basename: 'main',
          content: 'void main() {}',
          parts: [part1, part1],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should inject part directives after import statements', () {
      final part1 = PartFile(path: ['lib', 'src', 'part1'], content: '//');
      final part2 = PartFile(path: ['lib', 'src', 'part2'], content: '//');

      final dartFile = DartFile(
        basename: 'main',
        content: "import 'package:flutter/material.dart';\nvoid main() {}",
        parts: [part1, part2],
      );

      const expectedContent = '''
import 'package:flutter/material.dart';

part 'lib/src/part1.dart';
part 'lib/src/part2.dart';

void main() {}
''';

      expect(dartFile.content, expectedContent);
    });
  });
}
