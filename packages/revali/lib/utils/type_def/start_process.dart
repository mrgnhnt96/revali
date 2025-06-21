import 'dart:io';

typedef StartProcess = Future<ProcessDetails> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment,
  bool runInShell,
  ProcessStartMode mode,
});

Future<ProcessDetails> processToDetails(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment = true,
  bool runInShell = false,
  ProcessStartMode mode = ProcessStartMode.normal,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    mode: mode,
  );

  return ProcessDetails(
    stdout: process.stdout,
    stderr: process.stderr,
    pid: process.pid,
    exitCode: process.exitCode,
  );
}

class ProcessDetails {
  const ProcessDetails({
    required this.stdout,
    required this.stderr,
    required this.pid,
    required this.exitCode,
  });

  final Stream<List<int>> stdout;
  final Stream<List<int>> stderr;
  final int pid;
  final Future<int> exitCode;
}
