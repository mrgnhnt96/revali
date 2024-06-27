import 'dart:async';

void main() {
  _run();
}

Future<void> _run() async {
  await Future<void>.delayed(const Duration(seconds: 1));
  print('starting');
  await Future<void>.delayed(const Duration(seconds: 1));
  print('generating code...');
  await Future<void>.delayed(const Duration(seconds: 1));
  print('code generated');
  print('serving');
  var count = 0;

  while (true) {
    await Future<void>.delayed(const Duration(seconds: 1));
    print('lets go!!!');
    print('serving ${count++}');
  }
}
