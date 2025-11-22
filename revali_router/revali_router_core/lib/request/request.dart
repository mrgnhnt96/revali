import 'package:revali_router_core/body/body.dart';
import 'package:revali_router_core/method_mutations/headers/headers.dart';
import 'package:revali_router_core/payload/payload.dart';

abstract class Request {
  const Request();

  /// Resolves the payload of the request for [body] to be accessible.
  ///
  /// **!!! Important !!!**\
  /// This method should be called before accessing [body]
  Future<void> resolvePayload();

  /// The headers of the request.
  Headers get headers;

  /// The body of the request, resolved from the original payload.
  ///
  /// **!!! Important !!!**\
  /// This field can only be accessed after calling [resolvePayload].
  /// If the [body] is not resolved, this field will throw an exception,
  /// `UnresolvedPayloadException`.
  Body get body;

  /// The original payload of the request.
  Payload get originalPayload;

  /// The query parameters of the request.
  ///
  /// ## Example:
  /// `http://example.com?name=John`
  ///
  /// ```dart
  /// request.queryParameters['name'] // John
  /// ```
  ///
  /// ## Note:
  /// If there are multiple values for the same parameter, only the last
  /// value will be returned.
  ///
  /// ## Example:
  /// `http://example.com?name=John&name=Jane`
  ///
  /// ```dart
  /// request.queryParameters['name'] // Jane
  /// ```
  Map<String, dynamic> get queryParameters;

  /// The query parameters of the request, including multiple values for
  /// the same parameter, if any.
  ///
  /// ## Example:
  /// `http://example.com?name=John&name=Jane`
  ///
  /// ```dart
  /// request.queryParametersAll['name'] // [John, Jane]
  /// ```
  Map<String, Iterable<dynamic>> get queryParametersAll;

  /// The path parameters of the request.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// // /user/:id -> Path pattern
  /// // /user/123 -> Request path
  ///
  /// request.pathParameters['id'] // 123
  /// ```
  Map<String, String> get pathParameters;

  // This will be implemented in the future
  // ignore: unused_element
  Map<String, Iterable<String>> get _wildcardParameters;

  /// The HTTP method of the request.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// request.method // GET
  /// ```
  String get method;

  /// The URI of the request.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// request.uri // http://example.com/user/123
  /// ```
  Uri get uri;

  /// The segments of the request path.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// request.segments // [user, 123]
  /// ```
  Iterable<String> get segments;
}
