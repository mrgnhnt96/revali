import 'package:file/memory.dart';
import 'package:revali/clis/revali_runner/commands/utils/validate_tls_args.dart';
import 'package:test/test.dart';

void main() {
  group('validateTlsArgs', () {
    late MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      fs.file('/cert.pem').createSync(recursive: true);
      fs.file('/key.pem').createSync(recursive: true);
    });

    test('returns null when neither cert nor key is provided', () {
      final error = validateTlsArgs(cert: null, key: null, fs: fs);

      expect(error, isNull);
    });

    test('returns null when both cert and key exist', () {
      final error = validateTlsArgs(cert: '/cert.pem', key: '/key.pem', fs: fs);

      expect(error, isNull);
    });

    test('errors when only cert is provided', () {
      final error = validateTlsArgs(cert: '/cert.pem', key: null, fs: fs);

      expect(error, contains('must both be provided together'));
    });

    test('errors when only key is provided', () {
      final error = validateTlsArgs(cert: null, key: '/key.pem', fs: fs);

      expect(error, contains('must both be provided together'));
    });

    test('errors when the cert file does not exist', () {
      final error = validateTlsArgs(
        cert: '/missing-cert.pem',
        key: '/key.pem',
        fs: fs,
      );

      expect(error, contains('Cert file not found'));
      expect(error, contains('/missing-cert.pem'));
    });

    test('errors when the key file does not exist', () {
      final error = validateTlsArgs(
        cert: '/cert.pem',
        key: '/missing-key.pem',
        fs: fs,
      );

      expect(error, contains('Key file not found'));
      expect(error, contains('/missing-key.pem'));
    });
  });
}
