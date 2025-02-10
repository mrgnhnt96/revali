import 'package:hello/manual_gen/lib/implementations.dart';

void main() async {
  final server = Server();

  try {
    final response = await server.users.simple();

    print(response);
  } catch (e) {
    print(e);
  }
}
