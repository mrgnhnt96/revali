import 'package:revali_router_core/context/context.dart';
import 'package:revali_router_core/results/wrapper_result.dart';

abstract interface class RequestWrapper {
  const RequestWrapper();

  WrapperResult wrap(Context context, NextResponse next);
}
