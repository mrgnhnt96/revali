import 'package:revali_router/revali_router.dart';

class BoolPipe implements Pipe<String, bool> {
  const BoolPipe();

  @override
  Future<bool> transform(String value, PipeContext context) async {
    return value == 'true';
  }
}
