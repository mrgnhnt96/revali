import 'package:analyzer/dart/element/type.dart';
import 'package:revali_construct/models/meta_type.dart';

class MetaRecordProp {
  const MetaRecordProp({
    required this.name,
    required this.isNamed,
    required this.type,
  });

  static Iterable<MetaRecordProp> fromRecordType(RecordType type) sync* {
    for (final field in type.positionalFields) {
      final type = MetaType.fromType(field.type);

      yield MetaRecordProp(name: null, isNamed: false, type: type);
    }

    for (final field in type.namedFields) {
      final type = MetaType.fromType(field.type);

      yield MetaRecordProp(name: field.name, isNamed: true, type: type);
    }
  }

  final String? name;
  final bool isNamed;
  final MetaType type;

  bool get isPositioned => !isNamed;
}
