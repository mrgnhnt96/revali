import 'dart:convert';

import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/enums/output_format.dart';

AnyFile makeSwaggerFile(Map<String, dynamic> spec, OutputFormat format) {
  final (content, extension) = _formatSpec(spec, format);

  return AnyFile(basename: 'swagger', extension: extension, content: content);
}

List<AnyFile> makeSwaggerFiles(Map<String, dynamic> spec) {
  return [
    makeSwaggerFile(spec, OutputFormat.yaml),
    makeSwaggerFile(spec, OutputFormat.json),
  ];
}

(String content, String extension) _formatSpec(
  Map<String, dynamic> spec,
  OutputFormat format,
) {
  return switch (format) {
    OutputFormat.json => (
      const JsonEncoder.withIndent('  ').convert(spec),
      'json',
    ),
    OutputFormat.yaml => (_toYaml(spec, 0), 'yaml'),
  };
}

String _toYaml(dynamic value, int indent) {
  final buffer = StringBuffer();
  final pad = '  ' * indent;

  switch (value) {
    case final Map<Object?, Object?> map:
      if (map.isEmpty) {
        buffer.write('{}');
        return buffer.toString();
      }
      for (final entry in map.entries) {
        final key = _yamlKey(entry.key.toString());
        final val = entry.value;
        if (val is Map && val.isEmpty) {
          buffer.writeln('$pad$key: {}');
        } else if (val is List && val.isEmpty) {
          buffer.writeln('$pad$key: []');
        } else if (val is Map || val is List) {
          buffer
            ..writeln('$pad$key:')
            ..write(_toYamlIndented(val, indent + 1));
        } else {
          buffer.writeln('$pad$key: ${_yamlScalar(val)}');
        }
      }

    case final List<Object?> list:
      if (list.isEmpty) {
        buffer.write('[]');
        return buffer.toString();
      }
      for (final item in list) {
        if (item is Map || item is List) {
          buffer
            ..writeln('$pad-')
            ..write(_toYamlIndented(item, indent + 1));
        } else {
          buffer.writeln('$pad- ${_yamlScalar(item)}');
        }
      }

    default:
      buffer.write(_yamlScalar(value));
  }

  return buffer.toString();
}

String _toYamlIndented(dynamic value, int indent) {
  final pad = '  ' * indent;

  switch (value) {
    case final Map<Object?, Object?> map:
      final buffer = StringBuffer();
      for (final entry in map.entries) {
        final key = _yamlKey(entry.key.toString());
        final val = entry.value;
        if (val is Map && val.isEmpty) {
          buffer.writeln('$pad$key: {}');
        } else if (val is List && val.isEmpty) {
          buffer.writeln('$pad$key: []');
        } else if (val is Map || val is List) {
          buffer
            ..writeln('$pad$key:')
            ..write(_toYamlIndented(val, indent + 1));
        } else {
          buffer.writeln('$pad$key: ${_yamlScalar(val)}');
        }
      }
      return buffer.toString();

    case final List<Object?> list:
      final buffer = StringBuffer();
      for (final item in list) {
        if (item is Map<Object?, Object?>) {
          final entries = item.entries.toList();
          if (entries.isEmpty) {
            buffer.writeln('$pad- {}');
            continue;
          }
          final firstKey = _yamlKey(entries.first.key.toString());
          final firstVal = entries.first.value;
          if (firstVal is Map || firstVal is List) {
            buffer
              ..writeln('$pad- $firstKey:')
              ..write(_toYamlIndented(firstVal, indent + 2));
          } else {
            buffer.writeln('$pad- $firstKey: ${_yamlScalar(firstVal)}');
          }
          for (final entry in entries.skip(1)) {
            final key = _yamlKey(entry.key.toString());
            final val = entry.value;
            if (val is Map || val is List) {
              buffer
                ..writeln('$pad  $key:')
                ..write(_toYamlIndented(val, indent + 2));
            } else {
              buffer.writeln('$pad  $key: ${_yamlScalar(val)}');
            }
          }
        } else if (item is List) {
          buffer
            ..writeln('$pad-')
            ..write(_toYamlIndented(item, indent + 1));
        } else {
          buffer.writeln('$pad- ${_yamlScalar(item)}');
        }
      }
      return buffer.toString();

    default:
      return '${_yamlScalar(value)}\n';
  }
}

String _yamlKey(String key) {
  if (!RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_\-$/]*$').hasMatch(key)) {
    return "'${key.replaceAll("'", "''")}'";
  }
  // YAML 1.1 boolean/null literals must be quoted when used as keys.
  const yamlReserved = {
    'null',
    'true',
    'false',
    'yes',
    'no',
    'on',
    'off',
    'Null',
    'True',
    'False',
    'Yes',
    'No',
    'On',
    'Off',
    'NULL',
    'TRUE',
    'FALSE',
    'YES',
    'NO',
    'ON',
    'OFF',
  };
  if (yamlReserved.contains(key)) {
    return "'${key.replaceAll("'", "''")}'";
  }
  return key;
}

String _yamlScalar(dynamic value) {
  if (value == null) return 'null';
  if (value is bool) return value.toString();
  if (value is num) return value.toString();
  final str = value.toString();
  if (str.isEmpty) return "''";
  if (_needsQuoting(str)) {
    return "'${str.replaceAll("'", "''")}'";
  }
  return str;
}

bool _needsQuoting(String value) {
  if (const {
    'true',
    'false',
    'null',
    'yes',
    'no',
    'on',
    'off',
  }.contains(value.toLowerCase())) {
    return true;
  }
  if (double.tryParse(value) != null || int.tryParse(value) != null) {
    return true;
  }
  if (value.startsWith(RegExp(r'[:{}\[\],&*?|<>=!%@`#]'))) return true;
  if (value.contains(': ') || value.startsWith('- ')) return true;
  if (value.contains('\n') || value.contains('\r')) return true;
  return false;
}
