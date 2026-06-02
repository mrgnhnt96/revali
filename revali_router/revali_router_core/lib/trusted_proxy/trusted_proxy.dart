import 'dart:io';

import 'package:revali_router_core/method_mutations/headers/headers.dart';

/// Trusted reverse-proxy settings for resolving the client IP from headers.
///
/// When [headers] is empty, [resolve] uses only the TCP remote address.
/// Otherwise each header's comma-separated list is scanned for the first valid
/// IP (rightmost by default; leftmost when [useLeftmostIp] is true).
final class TrustedProxy {
  const TrustedProxy({
    this.headers = const [],
    this.useLeftmostIp = false,
  });

  /// Header names to check in order
  /// (e.g. `X-Forwarded-For`, `CF-Connecting-IP`).
  final List<String> headers;

  /// When `true`, use the leftmost valid IP in each header value.
  ///
  /// When `false` (default), use the rightmost valid IP — the value appended
  /// by your trusted proxy.
  final bool useLeftmostIp;

  String? resolve(String? remoteIp, Headers headers) {
    for (final headerName in this.headers) {
      final lines = headers.getAll(headerName);
      if (lines == null || lines.isEmpty) continue;

      final ipsList = lines.last;
      if (ipsList.isEmpty) continue;

      final ips =
          ipsList.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
      final ordered = useLeftmostIp ? ips : ips.toList().reversed;

      for (final candidate in ordered) {
        final parsed = _parseIp(candidate);
        if (parsed != null) return parsed;
      }
    }

    return remoteIp;
  }

  String? _parseIp(String value) {
    final host = _stripPort(value);
    final address = InternetAddress.tryParse(host);
    if (address == null) return null;
    return address.address;
  }

  String _stripPort(String value) {
    if (value.startsWith('[')) {
      final end = value.indexOf(']');
      if (end != -1) return value.substring(1, end);
    }

    final colon = value.lastIndexOf(':');
    if (colon == -1) return value;

    final after = value.substring(colon + 1);
    if (int.tryParse(after) != null) {
      return value.substring(0, colon);
    }

    return value;
  }
}
