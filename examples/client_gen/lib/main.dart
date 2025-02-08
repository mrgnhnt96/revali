import 'package:hello/manual_gen/server.dart';

void main() async {
  final server = Server();

  try {
    final response = await server.users.handle();

    print(response);
  } catch (e) {
    print(e);
  }
}
