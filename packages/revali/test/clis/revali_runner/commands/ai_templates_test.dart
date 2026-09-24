import 'package:revali/clis/revali_runner/commands/ai/ai_templates.dart';
import 'package:test/test.dart';

void main() {
  group('ai templates', () {
    final templates = {
      'CLAUDE.md': claudeMd,
      'copilot': copilotMd,
      ...cursorMdcFiles,
    };

    for (final MapEntry(key: name, value: content) in templates.entries) {
      group(name, () {
        test('pipes take a PipeContext', () {
          expect(content, isNot(contains('String value, Context context')));
        });

        test('does not claim query values are always String', () {
          expect(content, isNot(contains('`@Query()`/`@Header()` are always')));
          expect(
            content,
            isNot(contains('`@Query()`/`@Header()` values are always')),
          );
        });

        test('does not call revali_client or revali_swagger build '
            'constructs', () {
          expect(content, isNot(contains('client SDKs, Dockerfiles')));
        });

        test('does not say constructs come from regular dependencies', () {
          expect(content, isNot(contains('as a dependency and auto-detected')));
        });
      });
    }

    test('names the create_paths revali.yaml key', () {
      expect(claudeMd, contains('server.create_paths'));
      expect(claudeMd, isNot(contains('server.create_path`')));
    });

    test('documents that a String return is wrapped in data', () {
      expect(claudeMd, contains('including a plain `String`'));
    });
  });
}
