import 'package:revali_router/revali_router.dart';
import 'package:revali_router_annotations/src/apply_annotations/apply_annotations_context.dart';

class ApplyAnnotationsContextImpl implements ApplyAnnotationsContext {
  const ApplyAnnotationsContextImpl({
    required this.meta,
  });

  @override
  final MetaHandler meta;
}
