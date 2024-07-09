import 'package:analyzer/dart/element/element.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_shelf/converters/shelf_mimic.dart';

class ShelfReflect {
  const ShelfReflect({
    required this.className,
    required this.metas,
  });
  const ShelfReflect.none()
      : className = null,
        metas = null;

  factory ShelfReflect.fromElement(Element element) {
    if (element is! ClassElement) {
      return const ShelfReflect.none();
    }

    if (element.library.isInSdk) {
      return const ShelfReflect.none();
    }

    final className = element.displayName;

    final metas = <String, List<ShelfMimic>>{};

    for (final field in element.fields) {
      getAnnotations(
        element: field,
        onMatch: [
          OnMatch(
            classType: Meta,
            package: 'revali_router_annotations',
            convert: (object, annotation) {
              final meta = ShelfMimic.fromDartObject(object, annotation);
              (metas[field.name] ??= []).add(meta);
            },
          ),
        ],
      );
    }

    return ShelfReflect(
      className: className,
      metas: metas,
    );
  }

  final String? className;
  final Map<String, Iterable<ShelfMimic>>? metas;

  _ValidShelfReflect? get valid {
    if (!isValid) return null;

    return _ValidShelfReflect(
      className: className!,
      metas: metas!,
    );
  }

  bool get hasReflects => metas != null && metas!.isNotEmpty;
  bool get isValid => className != null && hasReflects;
}

class _ValidShelfReflect extends ShelfReflect {
  const _ValidShelfReflect({
    required String super.className,
    required Map<String, Iterable<ShelfMimic>> super.metas,
  })  : className = className,
        metas = metas;

  @override
  final String className;

  @override
  bool get hasReflects => true;

  @override
  bool get isValid => true;

  @override
  final Map<String, Iterable<ShelfMimic>> metas;
}
