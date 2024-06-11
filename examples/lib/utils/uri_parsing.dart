void main() {
  final uri = Uri.parse('/hello?name=John');

  print(uri.path); // /hello
  print(uri.queryParameters); // {name: John}
}
