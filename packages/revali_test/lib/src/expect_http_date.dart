import 'dart:io';

import 'package:test/test.dart';

/// Asserts [raw] is a valid HTTP-date (RFC 7231) within [within] of now.
///
/// Prefer this over `DateTime.parse` — response Date headers use
/// [HttpDate.format], not ISO-8601.
void expectRecentHttpDate(
  String? raw, {
  Duration within = const Duration(seconds: 5),
  DateTime? parsed,
}) {
  expect(raw, isNotNull, reason: 'expected a Date header');
  final fromRaw = HttpDate.parse(raw!);
  final cutoff = DateTime.now().toUtc().subtract(within);
  expect(
    fromRaw.isAfter(cutoff) || fromRaw.isAtSameMomentAs(cutoff),
    isTrue,
    reason: 'HTTP-date $raw is older than $within',
  );

  if (parsed != null) {
    expect(parsed.toUtc(), fromRaw);
  }
}

/// Matcher for a raw header value that parses as an HTTP-date.
Matcher isHttpDate() => isA<String>().having(
  HttpDate.parse,
  'parses as HTTP-date',
  isA<DateTime>(),
);
