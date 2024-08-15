import 'package:revali_construct/models/revali_context.dart';

class RevaliBuildContext extends RevaliContext {
  const RevaliBuildContext({
    required super.flavor,
    required super.mode,
    required this.defines,
  });

  final Map<String, String> defines;
}
