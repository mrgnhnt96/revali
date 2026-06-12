import 'package:revali_construct/revali_construct.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';
import 'package:revali_swagger/builders/schema_registry.dart';
import 'package:revali_swagger/models/swagger_param.dart';
import 'package:revali_swagger/models/swagger_type.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';

class SwaggerExplicitResponse {
  const SwaggerExplicitResponse({
    required this.statusCode,
    required this.description,
  });

  final int statusCode;
  final String description;
}

class SwaggerMethod {
  SwaggerMethod({
    required this.operationId,
    required this.httpMethod,
    required this.path,
    required this.parameters,
    required this.bodyParam,
    required this.returnType,
    required this.defaultStatusCode,
    required this.isHidden,
    required this.explicitResponses,
    this.summary,
    this.description,
    List<String> tags = const [],
  }) : tags = List.unmodifiable(tags);

  factory SwaggerMethod.fromMeta(
    MetaMethod method,
    String controllerName,
    SchemaRegistry registry,
  ) {
    String? summary;
    String? description;
    var isHidden = false;
    var defaultStatusCode = 200;
    final explicitResponses = <SwaggerExplicitResponse>[];
    final extraTags = <String>[];

    method.annotationsFor(
      onMatch: [
        OnMatch(
          classType: ApiSummary,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            summary = object.getField('text')?.toStringValue();
          },
        ),
        OnMatch(
          classType: ApiDescription,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            description = object.getField('text')?.toStringValue();
          },
        ),
        OnMatch(
          classType: ApiHidden,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            isHidden = true;
          },
        ),
        OnMatch(
          classType: ApiTag,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            final tag = object.getField('name')?.toStringValue();
            if (tag case final String tag) {
              extraTags.add(tag);
            }
          },
        ),
        OnMatch(
          classType: ApiResponse,
          package: 'revali_swagger_annotations',
          convert: (object, annotation) {
            final code = object.getField('statusCode')?.toIntValue() ?? 200;
            final desc =
                object.getField('description')?.toStringValue() ?? 'Response';
            explicitResponses.add(
              SwaggerExplicitResponse(statusCode: code, description: desc),
            );
          },
        ),
        OnMatch(
          classType: StatusCode,
          package: 'revali_router_annotations',
          convert: (object, annotation) {
            defaultStatusCode = object.getField('code')?.toIntValue() ?? 200;
          },
        ),
      ],
    );

    if (isHidden) {
      return SwaggerMethod(
        operationId: '${controllerName}_${method.name}',
        httpMethod: method.method.toLowerCase(),
        path: method.path ?? '',
        summary: summary,
        description: description,
        tags: extraTags,
        parameters: const [],
        bodyParam: null,
        returnType: const SwaggerType(schema: {}, isVoid: true),
        defaultStatusCode: defaultStatusCode,
        isHidden: true,
        explicitResponses: explicitResponses,
      );
    }

    final allParams = method.params
        .map((p) => SwaggerParam.fromMeta(p, registry))
        .whereType<SwaggerParam>()
        .toList();

    final bodyParam = allParams.where((p) => p.isBody).firstOrNull;
    final parameters = allParams.where((p) => !p.isBody).toList();

    return SwaggerMethod(
      operationId: '${controllerName}_${method.name}',
      httpMethod: method.method.toLowerCase(),
      path: method.path ?? '',
      summary: summary,
      description: description,
      tags: extraTags,
      parameters: parameters,
      bodyParam: bodyParam,
      returnType: SwaggerType.fromMeta(method.returnType, registry),
      defaultStatusCode: defaultStatusCode,
      isHidden: isHidden,
      explicitResponses: explicitResponses,
    );
  }

  final String operationId;
  final String httpMethod;
  final String path;
  final String? summary;
  final String? description;
  final List<String> tags;
  final List<SwaggerParam> parameters;
  final SwaggerParam? bodyParam;
  final SwaggerType returnType;
  final int defaultStatusCode;
  final bool isHidden;
  final List<SwaggerExplicitResponse> explicitResponses;
}
