import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:revali_client_gen/enums/parameter_position.dart';
import 'package:revali_client_gen/makers/utils/extract_import.dart';
import 'package:revali_client_gen/models/client_imports.dart';
import 'package:revali_client_gen/models/client_type.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

class ClientParam with ExtractImport {
  ClientParam({
    required this.name,
    required this.position,
    required this.type,
    required this.access,
    required this.acceptMultiple,
  });

  static ClientParam? fromElement(ParameterElement element) {
    final (:acceptMultiple, :access, :position) = _getPosition(
      element.name,
      ({required List<OnMatch> onMatch, NonMatch? onNonMatch}) =>
          getAnnotations(
        element: element,
        onMatch: onMatch,
        onNonMatch: onNonMatch,
      ),
    );

    if (position == null) {
      return null;
    }

    return ClientParam(
      name: element.name,
      type: ClientType.fromElement(element),
      position: position,
      access: access,
      acceptMultiple: acceptMultiple,
    );
  }

  static ClientParam? fromMeta(MetaParam parameter) {
    final (:acceptMultiple, :access, :position) = _getPosition(
      parameter.name,
      parameter.annotationsFor,
    );
    if (position == null) {
      return null;
    }

    return ClientParam(
      name: parameter.name,
      position: position,
      type: ClientType.fromMeta(parameter.type),
      access: access,
      acceptMultiple: acceptMultiple,
    );
  }

  static ({
    bool acceptMultiple,
    List<String> access,
    ParameterPosition? position
  }) _getPosition(
    String name,
    AnnotationMapper annotationsFor,
  ) {
    var acceptMultiple = false;
    ParameterPosition? position;
    final access = <String>[];

    void set(ParameterPosition value) {
      if (position != null) {
        throw Exception(
          'Found multiple annotations on parameter $name',
        );
      }

      position = value;
    }

    void getAccess(DartObject object) {
      if (access.isNotEmpty) {
        throw Exception(
          'Found multiple access points on parameter $name',
        );
      }

      if (object.getField('name')?.toStringValue() case final String name) {
        access.add(name);
      }

      if (object.getField('access')?.toListValue()
          case final List<dynamic> data) {
        access.addAll(
          data.map((e) {
            return switch (e) {
              DartObject() => e.toStringValue() ?? '',
              _ => '',
            };
          }),
        );
      }
    }

    annotationsFor(
      onMatch: [
        OnMatch(
          classType: Body,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            set(ParameterPosition.body);

            getAccess(object);
          },
        ),
        OnMatch(
          classType: Header,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            if (object.getField('all')?.toBoolValue() case true) {
              acceptMultiple = true;
            }
            set(ParameterPosition.header);
            getAccess(object);
          },
        ),
        OnMatch(
          classType: Query,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            if (object.getField('all')?.toBoolValue() case true) {
              acceptMultiple = true;
            }
            set(ParameterPosition.query);
            getAccess(object);
          },
        ),
        OnMatch(
          classType: Cookie,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            set(ParameterPosition.cookie);
            getAccess(object);
          },
        ),
      ],
    );

    return (
      acceptMultiple: acceptMultiple,
      access: access,
      position: position,
    );
  }

  static List<ClientParam> fromMetas(Iterable<MetaParam> params) {
    return params.map(fromMeta).whereType<ClientParam>().toList();
  }

  final String name;
  final List<String> access;
  final ClientType type;
  final ParameterPosition position;
  final bool acceptMultiple;

  ClientParam changeType(ClientType type) {
    return ClientParam(
      name: name,
      type: type,
      position: position,
      access: access,
      acceptMultiple: acceptMultiple,
    );
  }

  @override
  List<ExtractImport?> get extractors => [type];

  @override
  List<ClientImports?> get imports => [];
}
