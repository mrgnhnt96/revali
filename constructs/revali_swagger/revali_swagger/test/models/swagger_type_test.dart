import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_construct/models/meta_type.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/models/swagger_type.dart';
import 'package:test/test.dart';

MetaType primitive(String name, {bool isNullable = false}) {
  return MetaType(
    name: isNullable ? '$name?' : name,
    fromJson: null,
    toJson: null,
    importPath: null,
    isNullable: isNullable,
    element: null,
    iterableType: null,
    isRecord: false,
    isStream: false,
    isFuture: false,
    typeArguments: const [],
    recordProps: null,
    isVoid: false,
    isPrimitive: true,
    isDynamic: false,
    isMap: false,
    isEnum: false,
  );
}

MetaType voidType() {
  return const MetaType(
    name: 'void',
    fromJson: null,
    toJson: null,
    importPath: null,
    isNullable: false,
    element: null,
    iterableType: null,
    isRecord: false,
    isStream: false,
    isFuture: false,
    typeArguments: [],
    recordProps: null,
    isVoid: true,
    isPrimitive: false,
    isDynamic: false,
    isMap: false,
    isEnum: false,
  );
}

MetaType futureOf(MetaType inner) {
  return MetaType(
    name: 'Future<${inner.name}>',
    fromJson: null,
    toJson: null,
    importPath: null,
    isNullable: false,
    element: null,
    iterableType: null,
    isRecord: false,
    isStream: false,
    isFuture: true,
    typeArguments: [inner],
    recordProps: null,
    isVoid: false,
    isPrimitive: false,
    isDynamic: false,
    isMap: false,
    isEnum: false,
  );
}

MetaType listOf(MetaType inner) {
  return MetaType(
    name: 'List<${inner.name}>',
    fromJson: null,
    toJson: null,
    importPath: null,
    isNullable: false,
    element: null,
    iterableType: IterableType.list,
    isRecord: false,
    isStream: false,
    isFuture: false,
    typeArguments: [inner],
    recordProps: null,
    isVoid: false,
    isPrimitive: false,
    isDynamic: false,
    isMap: false,
    isEnum: false,
  );
}

void main() {
  late SchemaRegistry registry;

  setUp(() => registry = SchemaRegistry());

  group('SwaggerType.fromMeta — primitives', () {
    test('String → {type: string}', () {
      final t = SwaggerType.fromMeta(primitive('String'), registry);
      expect(t.schema, {'type': 'string'});
      expect(t.isVoid, isFalse);
    });

    test('int → {type: integer, format: int64}', () {
      final t = SwaggerType.fromMeta(primitive('int'), registry);
      expect(t.schema, {'type': 'integer', 'format': 'int64'});
    });

    test('double → {type: number, format: double}', () {
      final t = SwaggerType.fromMeta(primitive('double'), registry);
      expect(t.schema, {'type': 'number', 'format': 'double'});
    });

    test('bool → {type: boolean}', () {
      final t = SwaggerType.fromMeta(primitive('bool'), registry);
      expect(t.schema, {'type': 'boolean'});
    });

    test('nullable String adds nullable: true', () {
      final t = SwaggerType.fromMeta(
        primitive('String', isNullable: true),
        registry,
      );
      expect(t.schema, {'type': 'string', 'nullable': true});
    });
  });

  group('SwaggerType.fromMeta — void', () {
    test('void → isVoid: true, empty schema', () {
      final t = SwaggerType.fromMeta(voidType(), registry);
      expect(t.isVoid, isTrue);
      expect(t.schema, isEmpty);
    });

    test('Future<void> → isVoid: true', () {
      final t = SwaggerType.fromMeta(futureOf(voidType()), registry);
      expect(t.isVoid, isTrue);
    });
  });

  group('SwaggerType.fromMeta — Future unwrapping', () {
    test('Future<String> → String schema', () {
      final t = SwaggerType.fromMeta(futureOf(primitive('String')), registry);
      expect(t.schema, {'type': 'string'});
    });

    test('Future<int> → integer schema', () {
      final t = SwaggerType.fromMeta(futureOf(primitive('int')), registry);
      expect(t.schema, {'type': 'integer', 'format': 'int64'});
    });
  });

  group('SwaggerType.fromMeta — arrays', () {
    test('List<String> → {type: array, items: {type: string}}', () {
      final t = SwaggerType.fromMeta(listOf(primitive('String')), registry);
      expect(t.schema, {
        'type': 'array',
        'items': {'type': 'string'},
      });
    });

    test('Future<List<int>> → array of integers', () {
      final t = SwaggerType.fromMeta(
        futureOf(listOf(primitive('int'))),
        registry,
      );
      expect(t.schema['type'], 'array');
      expect(t.schema['items'], {'type': 'integer', 'format': 'int64'});
    });
  });

  group('SwaggerType.fromMeta — complex types', () {
    test(r'complex type registers in SchemaRegistry and returns $ref', () {
      const complexType = MetaType(
        name: 'User',
        fromJson: null,
        toJson: null,
        importPath: 'package:app/models/user.dart',
        isNullable: false,
        element: null,
        iterableType: null,
        isRecord: false,
        isStream: false,
        isFuture: false,
        typeArguments: [],
        recordProps: null,
        isVoid: false,
        isPrimitive: false,
        isDynamic: false,
        isMap: false,
        isEnum: false,
      );

      final t = SwaggerType.fromMeta(complexType, registry);
      expect(t.schema[r'$ref'], '#/components/schemas/User');
      expect(registry.schemasMap, contains('User'));
      expect(
        (registry.schemasMap['User'] as Map<String, dynamic>)['type'],
        'object',
      );
    });

    test('same complex type only registered once in SchemaRegistry', () {
      const complexType = MetaType(
        name: 'User',
        fromJson: null,
        toJson: null,
        importPath: null,
        isNullable: false,
        element: null,
        iterableType: null,
        isRecord: false,
        isStream: false,
        isFuture: false,
        typeArguments: [],
        recordProps: null,
        isVoid: false,
        isPrimitive: false,
        isDynamic: false,
        isMap: false,
        isEnum: false,
      );

      SwaggerType.fromMeta(complexType, registry);
      SwaggerType.fromMeta(complexType, registry);
      expect(registry.schemasMap.length, 1);
    });
  });
}
