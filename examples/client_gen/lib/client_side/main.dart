import 'package:client_server/server_client.dart';

void main() async {
  final server = Server();

  final subscription = server.points.myPoints().listen(print);

  await subscription.asFuture<void>();
  await subscription.cancel();
}
