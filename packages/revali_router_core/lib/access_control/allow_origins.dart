import 'package:revali_annotations/revali_annotations.dart' as annotations;

class AllowOrigins extends annotations.AllowOrigins {
  const AllowOrigins(super.origins, {super.inherit = true});
  const AllowOrigins.all() : super.all();
}
