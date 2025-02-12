import 'package:client_server/server_client.dart';

void main() async {
  final server = Server();

  try {
    final response = await server.users.simple();

    print(response);
  } catch (e) {
    print(e);
  }
}
