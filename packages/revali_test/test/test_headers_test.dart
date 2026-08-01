import 'dart:io';

import 'package:revali_test/revali_test.dart';
import 'package:test/test.dart';

void main() {
  group(TestHeaders, () {
    test('date setter writes HttpDate format', () {
      final headers = TestHeaders({});
      final now = DateTime.utc(2026, 8, 1, 12, 30, 45);

      headers.date = now;

      expect(headers.value(HttpHeaders.dateHeader), HttpDate.format(now));
      expect(headers.date, now);
    });

    test('date getter parses HttpDate strings from set()', () {
      final headers = TestHeaders({});
      final now = DateTime.utc(2026, 8, 1, 12, 30, 45);
      final formatted = HttpDate.format(now);

      headers.set(HttpHeaders.dateHeader, formatted);

      expect(headers.date, now);
      expect(headers.value(HttpHeaders.dateHeader), formatted);
    });

    test('set(DateTime) formats like dart:io', () {
      final headers = TestHeaders({});
      final now = DateTime.utc(2026, 8, 1, 12, 30, 45);

      headers.set(HttpHeaders.dateHeader, now);

      expect(headers.value(HttpHeaders.dateHeader), HttpDate.format(now));
      expect(headers.date, now);
    });
  });

  group('expectRecentHttpDate', () {
    test('accepts a fresh HttpDate string', () {
      expectRecentHttpDate(HttpDate.format(DateTime.now().toUtc()));
    });

    test('isHttpDate matches HttpDate strings', () {
      expect(HttpDate.format(DateTime.now().toUtc()), isHttpDate());
    });
  });
}
