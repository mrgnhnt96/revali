import 'package:analyzer/dart/element/element.dart';

class MetaType {
  const MetaType({
    required this.name,
    required this.hasFromJsonConstructor,
    required this.importPath,
    required this.element,
  });

  final String name;
  final bool hasFromJsonConstructor;
  final String? importPath;
  final Element? element;
}
