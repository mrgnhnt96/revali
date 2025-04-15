import 'package:revali_annotations/src/enums/instance_type.dart';

final class Controller {
  const Controller(this.path, {this.type = InstanceType.singleton});

  final String path;
  final InstanceType type;
}
