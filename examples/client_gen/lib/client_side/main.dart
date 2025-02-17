import 'package:client_gen_models/client_gen_models.dart';
import 'package:client_server/server_client.dart';

void main() async {
  final server = Server();

  await server.auth.login(
    email: 'email',
    password: 'password',
  );

  final users = await server.posts.handle(
    input: const CreatePostInput(title: 'Hello world!'),
    userId: '123',
  );

  print(users);
}
