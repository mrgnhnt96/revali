import 'package:mason_logger/mason_logger.dart';
import 'package:revali/services/service_discovery.dart';

/// One service, with everything the runner needs to start it.
class ServicePlan {
  const ServicePlan({
    required this.service,
    required this.port,
    required this.label,
  });

  final RevaliService service;

  /// The port handed to the process as `PORT`.
  final int port;

  /// What its output lines are prefixed with. Unique across the fleet.
  final String label;
}

/// Thrown when `--only` names something that is not there.
///
/// Silently running a subset of what was asked for is worse than refusing:
/// a typo would otherwise look like a service that starts and does nothing.
class UnknownServiceException implements Exception {
  const UnknownServiceException(this.names, this.available);

  final List<String> names;
  final List<String> available;

  @override
  String toString() =>
      'No such service: ${names.join(', ')}.\n'
      'Available: ${available.join(', ')}';
}

/// Decides what to run and on which ports.
///
/// Separated from the process handling so the decisions — selection, port
/// assignment, label uniqueness — are testable without starting anything.
List<ServicePlan> planServices(
  List<RevaliService> services, {
  int basePort = 8080,
  List<String> only = const [],
}) {
  final selected = _select(services, only);
  final labels = _labelsFor(selected);

  return [
    for (final (index, service) in selected.indexed)
      ServicePlan(
        service: service,
        port: basePort + index,
        label: labels[index],
      ),
  ];
}

List<RevaliService> _select(List<RevaliService> services, List<String> only) {
  if (only.isEmpty) {
    return services;
  }

  final wanted = only.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  final selected = services
      .where((s) => wanted.contains(s.name) || wanted.contains(s.relativePath))
      .toList();

  final matched = {
    for (final service in selected) ...[service.name, service.relativePath],
  };
  final missing = wanted.where((name) => !matched.contains(name)).toList();

  if (missing.isNotEmpty) {
    throw UnknownServiceException(
      missing,
      services.map((s) => s.name).toList(),
    );
  }

  return selected;
}

/// Labels for [services], one per entry and all distinct.
///
/// Package names are not unique across a repository — several examples can
/// legitimately be called `hello` — and two identical prefixes in a merged
/// output stream is worse than a long one, because there is then no way to
/// tell which process a line came from.
List<String> _labelsFor(List<RevaliService> services) {
  final counts = <String, int>{};
  for (final service in services) {
    counts[service.name] = (counts[service.name] ?? 0) + 1;
  }

  return [
    for (final service in services)
      if (counts[service.name] == 1) service.name else service.relativePath,
  ];
}

/// Prefixes every non-blank line of [chunk] with [label].
///
/// [label] arrives already padded and coloured — ANSI escapes count toward
/// string length, so padding here would misalign every prefix.
///
/// Returns the lines rather than printing them, so the caller decides where
/// they go and a test can look at them.
List<String> prefixLines(String chunk, String label) {
  return [
    // Split on carriage returns as well as newlines. Child processes redraw
    // progress with a bare `\r`, and left in place it returns the cursor to
    // column 0 — overwriting the very prefix that says which service the line
    // came from.
    for (final line in chunk.split(RegExp(r'[\r\n]+')))
      if (line.trim().isNotEmpty) '$label | $line',
  ];
}

/// A stable colour per service, so a given prefix keeps its colour for the
/// life of the run.
AnsiCode colorFor(int index) {
  const palette = [cyan, green, yellow, magenta, blue, red];

  return palette[index % palette.length];
}
