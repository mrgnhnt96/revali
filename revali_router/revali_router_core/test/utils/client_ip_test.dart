import 'package:revali_router_core/method_mutations/headers/headers.dart';
import 'package:revali_router_core/trusted_proxy/trusted_proxy.dart';
import 'package:test/test.dart';

final class _TestHeaders implements Headers {
  _TestHeaders(this._values);

  final Map<String, List<String>> _values;

  @override
  String? get(String key) {
    final values = getAll(key);
    return values?.lastOrNull;
  }

  @override
  List<String>? getAll(String key) {
    final normalized = key.toLowerCase();
    for (final entry in _values.entries) {
      if (entry.key.toLowerCase() == normalized) return entry.value;
    }
    return null;
  }

  @override
  Map<String, List<String>> get values => _values;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TrustedProxy.resolve', () {
    const remote = '10.0.0.1';
    late _TestHeaders headers;

    setUp(() {
      headers = _TestHeaders({});
    });

    test('returns remote IP when trusted proxy headers are not configured', () {
      headers = _TestHeaders({
        'x-forwarded-for': ['203.0.113.1, 198.51.100.178'],
      });

      expect(
        const TrustedProxy().resolve(remote, headers),
        remote,
      );
    });

    test('uses rightmost valid IP by default', () {
      headers = _TestHeaders({
        'x-forwarded-for': ['203.0.113.1, 198.51.100.178'],
      });

      expect(
        const TrustedProxy(headers: ['X-Forwarded-For']).resolve(
          remote,
          headers,
        ),
        '198.51.100.178',
      );
    });

    test('uses leftmost valid IP when useLeftmostIp is true', () {
      headers = _TestHeaders({
        'x-forwarded-for': ['203.0.113.1, 198.51.100.178'],
      });

      expect(
        const TrustedProxy(
          headers: ['X-Forwarded-For'],
          useLeftmostIp: true,
        ).resolve(remote, headers),
        '203.0.113.1',
      );
    });

    test('uses the last header line when duplicated', () {
      headers = _TestHeaders({
        'x-forwarded-for': ['1.1.1.1', '203.0.113.1, 198.51.100.178'],
      });

      expect(
        const TrustedProxy(headers: ['X-Forwarded-For']).resolve(
          remote,
          headers,
        ),
        '198.51.100.178',
      );
    });
  });
}
