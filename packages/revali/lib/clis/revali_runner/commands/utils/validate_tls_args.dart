import 'package:file/file.dart';

/// Validates `--cert`/`--key` CLI args for `revali dev`.
///
/// Returns an error message when they're invalid (only one provided, or a
/// path doesn't exist), or `null` when they're fine to use as-is (including
/// when neither is set).
String? validateTlsArgs({
  required String? cert,
  required String? key,
  required FileSystem fs,
}) {
  if (cert == null && key == null) {
    return null;
  }

  if (cert == null || key == null) {
    return '--cert and --key must both be provided together.';
  }

  if (!fs.file(cert).existsSync()) {
    return 'Cert file not found: $cert';
  }

  if (!fs.file(key).existsSync()) {
    return 'Key file not found: $key';
  }

  return null;
}
