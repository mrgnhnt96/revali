typedef AnnotationMapper = void Function({
  required List<OnClass> on,
});

class OnClass {
  const OnClass({
    required this.classType,
    required this.package,
    required this.convert,
  });

  final Type classType;
  final String package;
  final void Function(dynamic object, String source) convert;
}
