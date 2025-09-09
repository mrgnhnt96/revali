// ignore_for_file: overridden_fields

import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_server/converters/server_mimic.dart';

class ServerReflect {
  const ServerReflect({
    required this.className,
    required this.metas,
  });
  const ServerReflect.none()
      : className = null,
        metas = null;

  factory ServerReflect.fromElement(Element? element) {
    if (element == null) {
      return const ServerReflect.none();
    }

    if (element is! ClassElement) {
      return const ServerReflect.none();
    }

    if (element.library.isInSdk) {
      return const ServerReflect.none();
    }

    final className = element.displayName;

    final metas = <String, List<ServerMimic>>{};

    for (final field in element.fields) {
      getAnnotations(
        element: field,
        onMatch: [
          OnMatch(
            classType: MetaData,
            package: 'revali_router_annotations',
            convert: (object, annotation) {
              final meta = ServerMimic.fromDartObject(object, annotation);
              (metas[field.name] ??= []).add(meta);
            },
          ),
        ],
      );
    }

    return ServerReflect(
      className: className,
      metas: metas,
    );
  }

  final String? className;
  final Map<String, Iterable<ServerMimic>>? metas;

  // ignore: library_private_types_in_public_api
  _ValidServerReflect? get valid {
    if (!isValid) return null;

    return _ValidServerReflect(
      className: className!,
      metas: metas!,
    );
  }

  bool get hasReflects => metas != null && metas!.isNotEmpty;
  bool get isValid => className != null && hasReflects;
}

class _ValidServerReflect extends ServerReflect {
  const _ValidServerReflect({
    required String super.className,
    required Map<String, Iterable<ServerMimic>> super.metas,
    // ignore: prefer_initializing_formals
  })  : className = className,
        // ignore: prefer_initializing_formals
        metas = metas;

  @override
  final String className;

  @override
  bool get hasReflects => true;

  @override
  bool get isValid => true;

  @override
  final Map<String, Iterable<ServerMimic>> metas;
}
