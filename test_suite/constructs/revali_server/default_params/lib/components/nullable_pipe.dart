import 'package:revali_router/revali_router.dart';

class NullablePipe implements Pipe<String?, bool> {
  const NullablePipe();

  @override
  Future<bool> transform(String? value, PipeContext context) async {
    return switch (value) {
      null => true,
      final String v => v == 'true',
    };
  }
}
