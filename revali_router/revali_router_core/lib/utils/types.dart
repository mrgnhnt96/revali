import 'dart:async';

import 'package:revali_router_core/body/mutable_body.dart';

typedef PayloadTransformer = StreamTransformer<List<int>, List<int>>;
typedef Binary = List<int>;
typedef PayloadResolver = Future<MutableBody> Function();
