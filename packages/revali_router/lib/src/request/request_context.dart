import 'dart:convert';
import 'dart:io';

import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:http_parser/http_parser.dart';
import 'package:revali_router/src/request/parts/request.dart';

part 'request_context.g.dart';

class RequestContext extends Equatable {
  const RequestContext(this._request);
  RequestContext.from(HttpRequest request) : _request = Request.from(request);
  RequestContext.self(RequestContext context) : _request = context._request;

  @ignore
  final Request _request;

  @include
  List<String> get segments {
    final segments = _request.url.pathSegments;

    if (segments.isEmpty) {
      return [''];
    }

    return segments;
  }

  Future<String?> get body async {
    final body = await _request.readAsString();

    return body;
  }

  @include
  String get method => _request.method;

  @include
  Map<String, String> get headers => Map.unmodifiable(_request.headers);

  @include
  Map<String, String> get queryParameters =>
      Map.unmodifiable(_request.url.queryParameters);

  @include
  Map<String, List<String>> get queryParametersAll =>
      Map.unmodifiable(_request.url.queryParametersAll);

  @include
  Uri get uri => _request.url;

  @override
  List<Object?> get props => _$props;

  Encoding? get encoding => _request.encoding;

  Future<WebSocket> upgradeToWebSocket({Duration? ping}) {
    return _request.upgradeToWebSocket(ping: ping);
  }

  DateTime? get ifModifiedSince {
    if (!headers.containsKey('if-modified-since')) return null;
    return parseHttpDate(headers['if-modified-since']!);
  }
}
