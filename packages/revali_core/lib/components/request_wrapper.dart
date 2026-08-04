import 'package:revali_core/context/context.dart';
import 'package:revali_core/results/wrapper_result.dart';

abstract interface class RequestWrapper {
  const RequestWrapper();

  WrapperResult wrap(Context context, NextResponse next);
}
