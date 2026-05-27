import 'package:revali_construct/models/iterable_type.dart';
import 'package:revali_server/converters/server_body_annotation.dart';
import 'package:revali_server/converters/server_param.dart';
import 'package:revali_server/converters/server_param_annotations.dart';
import 'package:revali_server/converters/server_type.dart';
import 'package:revali_server/makers/utils/byte_stream_body_param.dart';
import 'package:test/test.dart';

ServerType listIntType() {
  return ServerType(
    name: 'List<int>',
    iterableType: IterableType.list,
    typeArguments: [ServerType(name: 'int', isPrimitive: true)],
  );
}

ServerParam bodyParam(ServerType type) {
  return ServerParam(
    name: 'bytes',
    type: type,
    annotations: ServerParamAnnotations(
      body: ServerBodyAnnotation(access: null, pipe: null),
      query: null,
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

void main() {
  group('byte stream body params', () {
    test('isByteStreamBodyParam matches Stream<List<int>>', () {
      final param = bodyParam(
        ServerType(
          name: 'Stream<List<int>>',
          isStream: true,
          typeArguments: [listIntType()],
        ),
      );

      expect(isByteStreamBodyParam(param), isTrue);
    });

    test('isByteStreamBodyParam rejects materialized List<int> body', () {
      expect(isByteStreamBodyParam(bodyParam(listIntType())), isFalse);
    });

    test('routeNeedsResolvePayload is false for stream-only routes', () {
      final param = bodyParam(
        ServerType(
          name: 'Stream<List<int>>',
          isStream: true,
          typeArguments: [listIntType()],
        ),
      );

      expect(routeNeedsResolvePayload([param]), isFalse);
    });

    test('routeNeedsResolvePayload is true when mixed with map body', () {
      final streamParam = bodyParam(
        ServerType(
          name: 'Stream<List<int>>',
          isStream: true,
          typeArguments: [listIntType()],
        ),
      );

      final mapParam = bodyParam(
        ServerType(name: 'Map<String, dynamic>', isMap: true),
      );

      expect(routeNeedsResolvePayload([streamParam, mapParam]), isTrue);
    });
  });
}
