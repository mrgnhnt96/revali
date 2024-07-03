import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';
import 'package:shelf/shelf.dart';

part 'request_context.g.dart';

class RequestContext extends Equatable {
  const RequestContext(this._request);
  RequestContext.from(RequestContext context) : _request = context._request;

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

  @override
  List<Object?> get props => _$props;
}
