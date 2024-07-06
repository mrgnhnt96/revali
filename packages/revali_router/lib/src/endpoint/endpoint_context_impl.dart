import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/endpoint/endpoint_context.dart';
import 'package:revali_router/src/request/mutable_request_context.dart';
import 'package:revali_router/src/response/mutable_response_context.dart';

class EndpointContextImpl implements EndpointContext {
  const EndpointContextImpl({
    required this.data,
    required this.request,
    required this.response,
  });

  @override
  final DataHandler data;

  @override
  final MutableRequestContext request;

  @override
  final MutableResponseContext response;
}