import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

class SwaggerType {
  const SwaggerType({required this.schema, this.isVoid = false});

  factory SwaggerType.fromMeta(MetaType type, SchemaRegistry registry) {
    if (type.isFuture || type.isStream) {
      if (type.typeArguments.isEmpty) {
        return const SwaggerType(schema: {}, isVoid: true);
      }
      final inner = type.typeArguments.first;
      if (inner.isVoid) {
        return const SwaggerType(schema: {}, isVoid: true);
      }
      return SwaggerType.fromMeta(inner, registry);
    }

    if (type.isVoid) {
      return const SwaggerType(schema: {}, isVoid: true);
    }

    if (type.isDynamic) {
      // OpenAPI has no typed "any"; an empty schema accepts any value.
      return const SwaggerType(schema: {});
    }

    final rawName = type.name.replaceAll('?', '');

    final primitiveSchema = switch (rawName) {
      'String' => <String, dynamic>{'type': 'string'},
      'int' => <String, dynamic>{'type': 'integer', 'format': 'int64'},
      'double' ||
      'num' => <String, dynamic>{'type': 'number', 'format': 'double'},
      'bool' => <String, dynamic>{'type': 'boolean'},
      _ => null,
    };

    if (primitiveSchema != null) {
      if (type.isNullable) {
        return SwaggerType(schema: {...primitiveSchema, 'nullable': true});
      }
      return SwaggerType(schema: primitiveSchema);
    }

    if (type.iterableType != null) {
      final itemSchema = type.typeArguments.isNotEmpty
          ? SwaggerType.fromMeta(type.typeArguments.first, registry).schema
          : <String, dynamic>{};
      final schema = <String, dynamic>{'type': 'array', 'items': itemSchema};
      if (type.isNullable) schema['nullable'] = true;
      return SwaggerType(schema: schema);
    }

    if (type.isMap) {
      final valueSchema = type.typeArguments.length == 2
          ? SwaggerType.fromMeta(type.typeArguments[1], registry).schema
          : <String, dynamic>{};
      final additionalProperties = _isUntypedSchema(valueSchema)
          ? true
          : valueSchema;
      final schema = <String, dynamic>{
        'type': 'object',
        'additionalProperties': additionalProperties,
      };
      if (type.isNullable) schema['nullable'] = true;
      return SwaggerType(schema: schema);
    }

    if (type.isRecord && type.recordProps != null) {
      final properties = <String, dynamic>{};
      final required = <String>[];
      var positionalIndex = 0;

      for (final prop in type.recordProps!) {
        final propName = prop.isNamed
            ? (prop.name ?? 'field$positionalIndex')
            : 'field${positionalIndex++}';
        properties[propName] = SwaggerType.fromMeta(prop.type, registry).schema;
        if (!prop.type.isNullable) {
          required.add(propName);
        }
      }

      final schema = <String, dynamic>{
        'type': 'object',
        'properties': properties,
        if (required.isNotEmpty) 'required': required,
      };
      if (type.isNullable) schema['nullable'] = true;
      return SwaggerType(schema: schema);
    }

    if (type.isEnum) {
      final enumRef = {r'$ref': '#/components/schemas/$rawName'};
      if (!registry.contains(rawName)) {
        registry.register(rawName, _buildEnumSchema(type.element, rawName));
      }
      if (type.isNullable) {
        return SwaggerType(
          schema: {
            'allOf': [enumRef],
            'nullable': true,
          },
        );
      }
      return SwaggerType(schema: enumRef);
    }

    // SDK types: a real analyzer element whose library is in the SDK has a
    // null importPath (see ElementX.importPath). User types have a package URI.
    // element == null means a hand-constructed MetaType (e.g. unit tests) —
    // treat those as opaque complex types instead.
    if (type.importPath == null && type.element != null) {
      final sdkSchema = _sdkTypeSchema(rawName, registry);
      if (type.isNullable) {
        return SwaggerType(schema: {...sdkSchema, 'nullable': true});
      }
      return SwaggerType(schema: sdkSchema);
    }

    // User-defined complex class: introspect fields.
    final classRef = {r'$ref': '#/components/schemas/$rawName'};

    // Early return if already registered (dedup + cycle detection).
    if (registry.contains(rawName)) {
      if (type.isNullable) {
        return SwaggerType(
          schema: {
            'allOf': [classRef],
            'nullable': true,
          },
        );
      }
      return SwaggerType(schema: classRef);
    }

    // Reserve before introspecting to break circular references.
    registry.reserve(rawName);

    Map<String, dynamic> inlineSchema;

    if (type.element is ClassElement) {
      final classEl = type.element! as ClassElement;

      // Sealed class: represent as oneOf with all direct subtypes.
      if (classEl.isSealed) {
        final subtypes = classEl.library.classes
            .where(
              (c) =>
                  c != classEl &&
                  (c.supertype?.element == classEl ||
                      c.interfaces.any((i) => i.element == classEl)),
            )
            .toList();

        if (subtypes.isNotEmpty) {
          final refs = <Map<String, dynamic>>[];
          for (final sub in subtypes) {
            final subName = sub.name;
            if (subName == null) continue;
            final subRef = {r'$ref': '#/components/schemas/$subName'};
            if (!registry.contains(subName)) {
              SwaggerType.fromMeta(MetaType.fromType(sub.thisType), registry);
            }
            refs.add(subRef);
          }
          inlineSchema = {'oneOf': refs};
        } else {
          // No subtypes found — fall back to field introspection.
          inlineSchema = _buildObjectSchema(classEl, rawName, registry);
        }
      } else {
        inlineSchema = _buildObjectSchema(classEl, rawName, registry);
      }
    } else {
      registry.addWarning(
        "Type '$rawName' has no introspectable element. "
        "Defaulting to '{type: object}'. "
        'Use @ApiType on the field or parameter to specify the type.',
      );
      inlineSchema = {'type': 'object'};
    }

    final ref = registry.register(rawName, inlineSchema);

    if (type.isNullable) {
      return SwaggerType(
        schema: {
          'allOf': [ref],
          'nullable': true,
        },
      );
    }
    return SwaggerType(schema: ref);
  }

  final Map<String, dynamic> schema;
  final bool isVoid;
}

/// True when [schema] carries no type information
/// (e.g. `{}` or `{nullable: true}`).
bool _isUntypedSchema(Map<String, dynamic> schema) {
  if (schema.isEmpty) return true;
  return schema.length == 1 && schema.containsKey('nullable');
}

/// Returns a JSON Schema for a known Dart SDK type, or warns and falls back.
Map<String, dynamic> _sdkTypeSchema(String name, SchemaRegistry registry) {
  return switch (name) {
    'DateTime' => {'type': 'string', 'format': 'date-time'},
    'Uri' => {'type': 'string', 'format': 'uri'},
    'BigInt' => {'type': 'integer'},
    'Uint8List' ||
    'Int8List' ||
    'Uint16List' ||
    'Int16List' ||
    'Uint32List' ||
    'Int32List' ||
    'Uint64List' ||
    'Int64List' ||
    'Float32List' ||
    'Float64List' => {'type': 'string', 'format': 'byte'},
    'Duration' => () {
      registry.addWarning(
        "Type 'Duration' has no standard JSON serialization format. "
        "Defaulting to 'string'. "
        'Add @ApiType to the field or parameter to specify the format '
        "(e.g. @ApiType('integer', format: 'int64') for milliseconds).",
      );
      return <String, dynamic>{'type': 'string'};
    }(),
    _ => () {
      registry.addWarning(
        "Unknown SDK type '$name'. "
        'Defaulting to an empty schema. '
        'Add @ApiType to the field or parameter to specify '
        'the serialized type.',
      );
      return <String, dynamic>{};
    }(),
  };
}

/// Builds an OpenAPI schema for an enum using its declared constants.
Map<String, dynamic> _buildEnumSchema(Element? element, String rawName) {
  if (element is EnumElement) {
    final values = element.constants
        .map((f) => f.name)
        .whereType<String>()
        .toList();
    if (values.isNotEmpty) {
      return {'type': 'string', 'enum': values};
    }
  }
  return {'type': 'string'};
}

/// Builds an `{type: object}` schema for a class, collecting fields from the
/// full superclass chain (stops at SDK boundaries).
Map<String, dynamic> _buildObjectSchema(
  ClassElement classEl,
  String rawName,
  SchemaRegistry registry,
) {
  final fields = _allInstanceFields(classEl);
  if (fields.isEmpty) return {'type': 'object'};

  final properties = <String, dynamic>{};
  final requiredFields = <String>[];

  for (final field in fields) {
    final fieldName = field.name;
    if (fieldName == null) continue;
    final fieldMeta = MetaType.fromType(field.type);
    final apiTypeOverride = _fieldApiType(field);
    if (apiTypeOverride != null) {
      properties[fieldName] = fieldMeta.isNullable
          ? {...apiTypeOverride, 'nullable': true}
          : apiTypeOverride;
    } else {
      properties[fieldName] = SwaggerType.fromMeta(fieldMeta, registry).schema;
    }
    if (!fieldMeta.isNullable) requiredFields.add(fieldName);
  }

  return {
    'type': 'object',
    'properties': properties,
    if (requiredFields.isNotEmpty) 'required': requiredFields,
  };
}

/// Collects all non-static, non-synthetic instance fields from [classEl] and
/// its superclass chain, stopping at SDK (dart:*) boundaries.
///
/// Subclass fields shadow superclass fields with the same name.
List<FieldElement> _allInstanceFields(ClassElement classEl) {
  final seen = <String>{};
  final result = <FieldElement>[];

  ClassElement? current = classEl;
  while (current != null && !current.library.isInSdk) {
    for (final field in current.fields) {
      final name = field.name;
      if (!field.isStatic &&
          !field.isSynthetic &&
          name != null &&
          seen.add(name)) {
        result.add(field);
      }
    }
    final superEl = current.supertype?.element;
    current = superEl is ClassElement ? superEl : null;
  }

  return result;
}

/// Reads an `@ApiType` annotation from a field element, if present.
Map<String, dynamic>? _fieldApiType(FieldElement field) {
  Map<String, dynamic>? result;
  getAnnotations(
    element: field,
    onMatch: [
      OnMatch(
        classType: ApiType,
        package: 'revali_swagger_annotations',
        convert: (object, annotation) {
          final type = object.getField('type')?.toStringValue();
          final format = object.getField('format')?.toStringValue();
          if (type != null) {
            result = {'type': type, if (format != null) 'format': format};
          }
        },
      ),
    ],
  );
  return result;
}
