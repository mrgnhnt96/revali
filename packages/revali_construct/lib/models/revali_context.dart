import 'package:revali_construct/enums/mode.dart';

class RevaliContext {
  const RevaliContext({
    required this.flavor,
    required this.mode,
  });

  final String? flavor;
  final Mode mode;
}
