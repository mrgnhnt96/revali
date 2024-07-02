import 'package:revali_annotations/models/pipes/argument_metadata.dart';

abstract class PipeTransform<T, R> {
  const PipeTransform();

  R transform(T value, ArgumentMetadata metadata);
}
