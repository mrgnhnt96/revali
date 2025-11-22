import 'package:code_builder/code_builder.dart';

Block tryCatch(Code tryBlock, Code catchBlock) {
  return Block.of([
    const Code('try {'),
    tryBlock,
    const Code('} catch (e) {'),
    catchBlock,
    const Code('}'),
  ]);
}
