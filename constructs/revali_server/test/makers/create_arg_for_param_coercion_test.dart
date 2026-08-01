import 'package:code_builder/code_builder.dart';
import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotations.dart';
import 'package:revali_server/converters/server_query_annotation.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/creators/create_arg_for_param.dart';
import 'package:test/test.dart';

void main() {
  group('createArgForParam query coercion', () {
    final emitter = DartEmitter.scoped(useNullSafetySyntax: true);

    ServerParam stringQueryParam() {
      return ServerParam(
        name: 'ms',
        type: ServerType(name: 'String', isPrimitive: true),
        annotations: ServerParamAnnotations(
          body: null,
          query: ServerQueryAnnotation(name: 'ms', pipe: null, all: false),
          header: null,
          cookie: null,
          ip: null,
          param: null,
          dep: false,
          data: false,
          binds: null,
          bind: null,
        ),
      );
    }

    ServerParam doubleQueryParam() {
      return ServerParam(
        name: 'n',
        type: ServerType(name: 'double', isPrimitive: true),
        annotations: ServerParamAnnotations(
          body: null,
          query: ServerQueryAnnotation(name: 'n', pipe: null, all: false),
          header: null,
          cookie: null,
          ip: null,
          param: null,
          dep: false,
          data: false,
          binds: null,
          bind: null,
        ),
      );
    }

    test('String query params stringify coerced num/bool values', () {
      final param = stringQueryParam();
      final code = createArgForParam(
        param.annotations.query!,
        param,
      ).accept(emitter).toString();

      expect(code, contains('num'));
      expect(code, contains('bool'));
      expect(code, contains('data.toString()'));
      expect(code, isNot(contains('Object data')));
    });

    test('double query params promote coerced nums via toDouble', () {
      final param = doubleQueryParam();
      final code = createArgForParam(
        param.annotations.query!,
        param,
      ).accept(emitter).toString();

      expect(code, contains('num'));
      expect(code, contains('data.toDouble()'));
    });

    test('List<String> query-all matches untyped List then casts', () {
      final param = ServerParam(
        name: 'shopIds',
        type: ServerType(
          name: 'List<String>',
          iterableType: IterableType.list,
          typeArguments: [ServerType(name: 'String', isPrimitive: true)],
        ),
        annotations: ServerParamAnnotations(
          body: null,
          query: ServerQueryAnnotation(name: 'shopId', pipe: null, all: true),
          header: null,
          cookie: null,
          ip: null,
          param: null,
          dep: false,
          data: false,
          binds: null,
          bind: null,
        ),
      );

      final code = createArgForParam(
        param.annotations.query!,
        param,
      ).accept(emitter).toString();

      expect(code, contains('List'));
      expect(code, contains('.cast<String>()'));
      expect(code, isNot(contains('List<String>')));
    });
  });
}
