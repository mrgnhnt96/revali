// ignore_for_file: one_member_abstracts

import 'dart:io';

import 'package:revali_router_core/context/request_context.dart';
import 'package:revali_router_core/response/read_only_response.dart';

abstract interface class ResponseHandler {
  const ResponseHandler();

  Future<void> handle(
    ReadOnlyResponse response,
    RequestContext context,
    HttpResponse httpResponse,
  );
}
