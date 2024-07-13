import 'dart:async';

import 'package:revali_router_core/body/read_only_body.dart';

typedef PayloadTransformer = StreamTransformer<List<int>, List<int>>;
typedef Binary = List<List<int>>;
typedef PayloadResolver = Future<ReadOnlyBody> Function();
