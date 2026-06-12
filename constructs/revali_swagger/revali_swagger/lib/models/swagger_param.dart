import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/enums/param_location.dart';
import 'package:revali_swagger/models/swagger_type.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

class SwaggerParam {
  SwaggerParam({
    required this.name,
    required this.location,
    required this.type,
    required this.isRequired,
    this.wireName,
  });

  static SwaggerParam? fromMeta(MetaParam param, SchemaRegistry registry) {
    ParamLocation? location;
    String? wireName;
    Map<String, dynamic>? apiTypeOverride;

    void setLocation(ParamLocation value) {
      if (location != null) {
        throw ArgumentError(
          'Found multiple binding annotations on parameter "${param.name}"',
        );
      }
      location = value;
    }

    param.annotationsFor(
      onMatch: [
        OnMatch(
          classType: Body,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            setLocation(ParamLocation.body);
            final access = object.getField('access')?.toListValue();
            if (access != null && access.isNotEmpty) {
              wireName ??= access.last.toStringValue();
            }
            wireName ??= object.getField('name')?.toStringValue();
          },
        ),
        OnMatch(
          classType: Query,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            setLocation(ParamLocation.query);
            wireName ??= object.getField('name')?.toStringValue();
          },
        ),
        OnMatch(
          classType: Param,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            setLocation(ParamLocation.path);
            wireName ??= object.getField('name')?.toStringValue();
          },
        ),
        OnMatch(
          classType: Header,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            setLocation(ParamLocation.header);
            wireName ??= object.getField('name')?.toStringValue();
          },
        ),
        OnMatch(
          classType: Cookie,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            setLocation(ParamLocation.cookie);
            wireName ??= object.getField('name')?.toStringValue();
          },
        ),
        OnMatch(
          classType: ApiType,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            final type = object.getField('type')?.toStringValue();
            final format = object.getField('format')?.toStringValue();
            if (type != null) {
              apiTypeOverride = {
                'type': type,
                if (format != null) 'format': format,
              };
            }
          },
        ),
      ],
    );

    if (location == null) return null;

    final resolvedLocation = location!;

    // OpenAPI 3.0.3 §4.8.12.1: these header names SHALL be ignored.
    // Omit them to avoid validator warnings.
    if (resolvedLocation == ParamLocation.header) {
      const reserved = {'authorization', 'content-type', 'accept'};
      if (reserved.contains((wireName ?? param.name).toLowerCase())) {
        return null;
      }
    }

    // Path params are always required per OpenAPI spec; for other locations
    // a nullable type implies optional even if the Dart param is positional.
    final isRequired =
        resolvedLocation == ParamLocation.path ||
        (param.isRequired && !param.type.isNullable);

    final resolvedType = apiTypeOverride != null
        ? SwaggerType(
            schema: param.type.isNullable
                ? {...apiTypeOverride!, 'nullable': true}
                : apiTypeOverride!,
          )
        : SwaggerType.fromMeta(param.type, registry);

    return SwaggerParam(
      name: param.name,
      location: resolvedLocation,
      type: resolvedType,
      isRequired: isRequired,
      wireName: wireName,
    );
  }

  final String name;
  final ParamLocation location;
  final SwaggerType type;
  final bool isRequired;

  /// Override name from annotation (e.g. @Query('page_size') → 'page_size').
  final String? wireName;

  String get effectiveName => wireName ?? name;

  bool get isBody => location == ParamLocation.body;
}
