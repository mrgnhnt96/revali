import 'package:code_builder/code_builder.dart';

Block tryCatch(
  Code tryBlock,
  Code catchBlock,
) {
  return Block.of([
    Code('try {'),
    tryBlock,
    Code('} catch (e) {'),
    catchBlock,
    Code('}'),
  ]);
}
