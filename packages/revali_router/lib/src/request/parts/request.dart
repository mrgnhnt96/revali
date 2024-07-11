// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

import 'message.dart';

/// An HTTP request to be processed by a Shelf application.
class Request extends Message {
  /// Creates a new [Request].
  ///
  /// [handlerPath] must be root-relative. [url]'s path must be fully relative,
  /// and it must have the same query parameters as [requestedUri].
  /// [handlerPath] and [url]'s path must combine to be the path component of
  /// [requestedUri]. If they're not passed, [handlerPath] will default to `/`
  /// and [url] to `requestedUri.path` without the initial `/`. If only one is
  /// passed, the other will be inferred.
  ///
  /// [body] is the request body. It may be either a [String], a [List<int>], a
  /// [Stream<List<int>>], or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a [Stream<List<int>>]. The default
  /// encoding is UTF-8.
  ///
  /// If [encoding] is passed, the "encoding" field of the Content-Type header
  /// in [headers] will be set appropriately. If there is no existing
  /// Content-Type header, it will be set to "application/octet-stream".
  /// [headers] must contain values that are either `String` or `List<String>`.
  /// An empty list will cause the header to be omitted.
  ///
  /// The default value for [protocolVersion] is '1.1'.
  Request(
    String method,
    Uri requestedUri, {
    required HttpRequest request,
    String? protocolVersion,
    Map<String, /* String | List<String> */ Object>? headers,
    String? handlerPath,
    Uri? url,
    Object? body,
    Encoding? encoding,
  }) : this._(
          method,
          requestedUri,
          request: request,
          protocolVersion: protocolVersion,
          headers: headers,
          url: url,
          handlerPath: handlerPath,
          body: body,
          encoding: encoding,
        );

  Request.from(HttpRequest request)
      : this(
          request.method,
          request.requestedUri,
          request: request,
          protocolVersion: request.protocolVersion,
          headers: request.headers.asMap(),
          body: request,
        );

  /// This constructor has the same signature as [Request.new] except that
  /// accepts [onHijack] as [_OnHijack].
  ///
  /// Any [Request] created by calling [change] will pass [_onHijack] from the
  /// source [Request] to ensure that [hijack] can only be called once, even
  /// from a changed [Request].
  Request._(
    this.method,
    this.requestedUri, {
    required this.request,
    String? protocolVersion,
    Map<String, /* String | List<String> */ Object>? headers,
    String? handlerPath,
    Uri? url,
    Object? body,
    Encoding? encoding,
  })  : protocolVersion = protocolVersion ?? '1.1',
        url = _computeUrl(requestedUri, handlerPath, url),
        handlerPath = _computeHandlerPath(requestedUri, handlerPath, url),
        super(
          body,
          encoding: encoding,
          headers: headers,
        ) {
    if (method.isEmpty) {
      throw ArgumentError.value(method, 'method', 'cannot be empty.');
    }

    try {
      // Trigger URI parsing methods that may throw format exception (in Request
      // constructor or in handlers / routing).
      requestedUri.pathSegments;
      requestedUri.queryParametersAll;
    } on FormatException catch (e) {
      throw ArgumentError.value(
          requestedUri, 'requestedUri', 'URI parsing failed: $e');
    }

    if (!requestedUri.isAbsolute) {
      throw ArgumentError.value(
          requestedUri, 'requestedUri', 'must be an absolute URL.');
    }

    if (requestedUri.fragment.isNotEmpty) {
      throw ArgumentError.value(
          requestedUri, 'requestedUri', 'may not have a fragment.');
    }

    // Notice that because relative paths must encode colon (':') as %3A we
    // cannot actually combine this.handlerPath and this.url.path, but we can
    // compare the pathSegments. In practice exposing this.url.path as a Uri
    // and not a String is probably the underlying flaw here.
    final handlerPart = Uri(path: this.handlerPath).pathSegments.join('/');
    final rest = this.url.pathSegments.join('/');
    final join = this.url.path.startsWith('/') ? '/' : '';
    final pathSegments = '$handlerPart$join$rest';
    if (pathSegments != requestedUri.pathSegments.join('/')) {
      throw ArgumentError.value(
          requestedUri,
          'requestedUri',
          'handlerPath "${this.handlerPath}" and url "${this.url}" must '
              'combine to equal requestedUri path "${requestedUri.path}".');
    }
  }

  /// The URL path from the current handler to the requested resource, relative
  /// to [handlerPath], plus any query parameters.
  ///
  /// This should be used by handlers for determining which resource to serve,
  /// in preference to [requestedUri]. This allows handlers to do the right
  /// thing when they're mounted anywhere in the application. Routers should be
  /// sure to update this when dispatching to a nested handler, using the
  /// `path` parameter to [change].
  ///
  /// [url]'s path is always relative. It may be empty, if [requestedUri] ends
  /// at this handler. [url] will always have the same query parameters as
  /// [requestedUri].
  ///
  /// [handlerPath] and [url]'s path combine to create [requestedUri]'s path.
  final Uri url;

  /// The HTTP request method, such as "GET" or "POST".
  final String method;

  final HttpRequest request;

  /// The URL path to the current handler.
  ///
  /// This allows a handler to know its location within the URL-space of an
  /// application. Routers should be sure to update this when dispatching to a
  /// nested handler, using the `path` parameter to [change].
  ///
  /// [handlerPath] is always a root-relative URL path; that is, it always
  /// starts with `/`. It will also end with `/` whenever [url]'s path is
  /// non-empty, or if [requestedUri]'s path ends with `/`.
  ///
  /// [handlerPath] and [url]'s path combine to create [requestedUri]'s path.
  final String handlerPath;

  /// The HTTP protocol version used in the request, either "1.0" or "1.1".
  final String protocolVersion;

  /// The original [Uri] for the request.
  final Uri requestedUri;

  /// If this is non-`null` and the requested resource hasn't been modified
  /// since this date and time, the server should return a 304 Not Modified
  /// response.
  ///
  /// This is parsed from the If-Modified-Since header in [headers]. If
  /// [headers] doesn't have an If-Modified-Since header, this will be `null`.
  ///
  /// Throws [FormatException], if incoming HTTP request has an invalid
  /// If-Modified-Since header.
  DateTime? get ifModifiedSince {
    if (_ifModifiedSinceCache != null) return _ifModifiedSinceCache;
    if (!headers.containsKey('if-modified-since')) return null;
    _ifModifiedSinceCache = parseHttpDate(headers['if-modified-since']!);
    return _ifModifiedSinceCache;
  }

  DateTime? _ifModifiedSinceCache;

  Future<WebSocket> upgradeToWebSocket() async {
    final webSocket = await WebSocketTransformer.upgrade(request);

    return webSocket;
  }
}

/// Computes `url` from the provided [Request] constructor arguments.
///
/// If [url] is `null`, the value is inferred from [requestedUri] and
/// [handlerPath] if available. Otherwise [url] is returned.
Uri _computeUrl(Uri requestedUri, String? handlerPath, Uri? url) {
  if (handlerPath != null &&
      handlerPath != requestedUri.path &&
      !handlerPath.endsWith('/')) {
    handlerPath += '/';
  }

  if (url != null) {
    if (url.scheme.isNotEmpty || url.hasAuthority || url.fragment.isNotEmpty) {
      throw ArgumentError('url "$url" may contain only a path and query '
          'parameters.');
    }

    if (!requestedUri.path.endsWith(url.path)) {
      throw ArgumentError('url "$url" must be a suffix of requestedUri '
          '"$requestedUri".');
    }

    if (requestedUri.query != url.query) {
      throw ArgumentError('url "$url" must have the same query parameters '
          'as requestedUri "$requestedUri".');
    }

    if (url.path.startsWith('/')) {
      throw ArgumentError('url "$url" must be relative.');
    }

    var startOfUrl = requestedUri.path.length - url.path.length;
    if (url.path.isNotEmpty &&
        requestedUri.path.substring(startOfUrl - 1, startOfUrl) != '/') {
      throw ArgumentError('url "$url" must be on a path boundary in '
          'requestedUri "$requestedUri".');
    }

    return url;
  } else if (handlerPath != null) {
    return Uri(
        path: requestedUri.path.substring(handlerPath.length),
        query: requestedUri.query);
  } else {
    // Skip the initial "/".
    var path = requestedUri.path.substring(1);
    return Uri(path: path, query: requestedUri.query);
  }
}

/// Computes `handlerPath` from the provided [Request] constructor arguments.
///
/// If [handlerPath] is `null`, the value is inferred from [requestedUri] and
/// [url] if available. Otherwise [handlerPath] is returned.
String _computeHandlerPath(Uri requestedUri, String? handlerPath, Uri? url) {
  if (handlerPath != null &&
      handlerPath != requestedUri.path &&
      !handlerPath.endsWith('/')) {
    handlerPath += '/';
  }

  if (handlerPath != null) {
    if (!requestedUri.path.startsWith(handlerPath)) {
      throw ArgumentError('handlerPath "$handlerPath" must be a prefix of '
          'requestedUri path "${requestedUri.path}"');
    }

    if (!handlerPath.startsWith('/')) {
      throw ArgumentError('handlerPath "$handlerPath" must be root-relative.');
    }

    return handlerPath;
  } else if (url != null) {
    if (url.path.isEmpty) return requestedUri.path;

    var index = requestedUri.path.indexOf(url.path);
    return requestedUri.path.substring(0, index);
  } else {
    return '/';
  }
}

extension _HttpHeadersX on HttpHeaders {
  Map<String, List<String>> asMap() {
    final map = <String, List<String>>{};

    forEach((name, values) {
      map[name] = values;
    });

    return map;
  }
}
