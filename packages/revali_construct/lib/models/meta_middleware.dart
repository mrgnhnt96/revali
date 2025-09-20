import 'package:analyzer/dart/constant/value.dart';

class MetaMiddleware {
  const MetaMiddleware({required this.name, required this.element});

  final String name;
  final DartObject element;
}
