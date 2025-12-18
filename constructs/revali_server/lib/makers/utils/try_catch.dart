import 'package:code_builder/code_builder.dart';

Block tryCatch(Code tryBlock, Code catchBlock, {bool stack = false}) {
  return Block.of([
    const Code('try {'),
    tryBlock,
    if (stack)
      const Code('} catch (e, stack) {')
    else
      const Code('} catch (e) {'),
    catchBlock,
    const Code('}'),
  ]);
}
