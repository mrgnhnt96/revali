import 'package:revali_router/src/data/data_handler.dart';
import 'package:revali_router/src/middleware/middleware_context.dart';
import 'package:revali_router/src/request/mutable_request_context_impl.dart';

// ignore: must_be_immutable
class MiddlewareContextImpl extends MutableRequestContextImpl
    implements MiddlewareContext {
  MiddlewareContextImpl(super.request, {required this.data});
  MiddlewareContextImpl.from(super.request, {required this.data})
      : super.from();

  @override
  final DataHandler data;
}
