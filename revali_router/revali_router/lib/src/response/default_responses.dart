import 'package:revali_router/src/response/simple_response.dart';

class DefaultResponses {
  const DefaultResponses({
    SimpleResponse? internalServerError,
    SimpleResponse? notFound,
    SimpleResponse? failedCorsOrigin,
    SimpleResponse? failedCorsHeaders,
  })  : _internalServerError = internalServerError,
        _notFound = notFound,
        _failedCorsOrigin = failedCorsOrigin,
        _failedCorsHeaders = failedCorsHeaders;

  final SimpleResponse? _internalServerError;
  SimpleResponse get internalServerError {
    if (_internalServerError case final response?) {
      return response;
    }

    return SimpleResponse(
      500,
      body: 'Internal Server Error',
    );
  }

  final SimpleResponse? _notFound;
  SimpleResponse get notFound {
    if (_notFound case final response?) {
      return response;
    }

    return SimpleResponse(
      404,
      body: 'Not Found',
    );
  }

  final SimpleResponse? _failedCorsOrigin;
  SimpleResponse get failedCorsOrigin {
    if (_failedCorsOrigin case final response?) {
      return response;
    }

    return SimpleResponse(
      403,
      body: 'CORS policy does not allow access from this origin.',
    );
  }

  final SimpleResponse? _failedCorsHeaders;
  SimpleResponse get failedCorsHeaders {
    if (_failedCorsHeaders case final response?) {
      return response;
    }

    return SimpleResponse(
      403,
      body: 'CORS policy does not allow access with these headers.',
    );
  }
}
