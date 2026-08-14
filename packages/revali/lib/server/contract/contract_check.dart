/// Compares two route manifests and reports what changed.
///
/// This is **drift detection, not client generation.** `routes.json` describes
/// a route *surface* — methods, paths, parameter names, locations and
/// requiredness, and the top-level name of what each handler returns. It
/// carries no field lists, no nested types and no serialisation strategy, so
/// it cannot produce a typed client and does not try to. What it can do is
/// tell a consumer that the producer moved underneath it, which is the part
/// that actually breaks deployments.
///
/// A consumer pins the manifest it built against; CI compares the producer's
/// current manifest to that pin.
library;

/// How much a single difference matters to a consumer.
enum ContractSeverity {
  /// The consumer's existing calls still work.
  compatible,

  /// The consumer's existing calls may now fail.
  breaking,
}

/// One difference between a pinned manifest and a current one.
class ContractChange {
  const ContractChange({
    required this.severity,
    required this.route,
    required this.description,
  });

  final ContractSeverity severity;

  /// `GET /api/users/:id`, or `manifest` for whole-file differences.
  final String route;

  final String description;

  bool get isBreaking => severity == ContractSeverity.breaking;

  @override
  String toString() => '$route: $description';
}

/// The result of comparing a pinned manifest against a current one.
class ContractReport {
  const ContractReport(this.changes);

  final List<ContractChange> changes;

  List<ContractChange> get breaking =>
      changes.where((c) => c.isBreaking).toList();

  List<ContractChange> get compatible =>
      changes.where((c) => !c.isBreaking).toList();

  bool get hasBreaking => breaking.isNotEmpty;
}

/// Compares [pinned] against [current], both decoded `routes.json` payloads.
ContractReport checkContract(
  Map<String, dynamic> pinned,
  Map<String, dynamic> current,
) {
  final changes = <ContractChange>[];

  final pinnedVersion = pinned['version'] as int? ?? 0;
  final currentVersion = current['version'] as int? ?? 0;

  // Version 1 has no `returns`, so absent must not be read as "unchanged" —
  // that would report a clean check for a comparison it cannot make.
  final canCompareReturns = pinnedVersion >= 2 && currentVersion >= 2;
  if (!canCompareReturns) {
    changes.add(
      const ContractChange(
        severity: ContractSeverity.compatible,
        route: 'manifest',
        description:
            'return types not compared: one side predates manifest version 2. '
            'Re-pin against a current manifest to include them.',
      ),
    );
  }

  final pinnedRoutes = _byKey(pinned);
  final currentRoutes = _byKey(current);

  for (final MapEntry(key: key, value: before) in pinnedRoutes.entries) {
    final after = currentRoutes[key];

    if (after == null) {
      changes.add(
        ContractChange(
          severity: ContractSeverity.breaking,
          route: key,
          description: 'route removed',
        ),
      );
      continue;
    }

    changes.addAll(
      _compareRoute(key, before, after, canCompareReturns: canCompareReturns),
    );
  }

  for (final key in currentRoutes.keys) {
    if (!pinnedRoutes.containsKey(key)) {
      // Additive: nothing the consumer already calls is affected.
      changes.add(
        ContractChange(
          severity: ContractSeverity.compatible,
          route: key,
          description: 'route added',
        ),
      );
    }
  }

  return ContractReport(changes);
}

Iterable<ContractChange> _compareRoute(
  String key,
  Map<String, dynamic> before,
  Map<String, dynamic> after, {
  required bool canCompareReturns,
}) sync* {
  if (canCompareReturns) {
    final wasReturning = before['returns'];
    final nowReturning = after['returns'];

    if (wasReturning != nowReturning) {
      yield ContractChange(
        severity: ContractSeverity.breaking,
        route: key,
        description: 'returns $wasReturning, now $nowReturning',
      );
    } else if (before['returnsNullable'] != true &&
        after['returnsNullable'] == true) {
      // The consumer may be dereferencing it without a null check.
      yield ContractChange(
        severity: ContractSeverity.breaking,
        route: key,
        description: 'return value is now nullable',
      );
    }
  }

  if (before['sse'] != after['sse'] ||
      before['webSocket'] != after['webSocket']) {
    yield ContractChange(
      severity: ContractSeverity.breaking,
      route: key,
      description: 'transport changed (sse/webSocket)',
    );
  }

  final beforeParams = _paramsByName(before);
  final afterParams = _paramsByName(after);

  for (final MapEntry(key: name, value: was) in beforeParams.entries) {
    final now = afterParams[name];

    if (now == null) {
      // Not breaking on its own: a server that stops reading a parameter
      // still accepts a caller that sends it. Worth reporting, because the
      // caller's value is now silently ignored.
      yield ContractChange(
        severity: ContractSeverity.compatible,
        route: key,
        description:
            "parameter '$name' removed; callers sending it are "
            'now ignored',
      );
      continue;
    }

    if (was['type'] != now['type']) {
      yield ContractChange(
        severity: ContractSeverity.breaking,
        route: key,
        description: "parameter '$name' was ${was['type']}, now ${now['type']}",
      );
    }

    if (was['location'] != now['location']) {
      yield ContractChange(
        severity: ContractSeverity.breaking,
        route: key,
        description:
            "parameter '$name' moved from ${was['location']} "
            'to ${now['location']}',
      );
    }

    if (was['required'] != true && now['required'] == true) {
      yield ContractChange(
        severity: ContractSeverity.breaking,
        route: key,
        description: "parameter '$name' is now required",
      );
    }
  }

  for (final MapEntry(key: name, value: now) in afterParams.entries) {
    if (beforeParams.containsKey(name)) {
      continue;
    }

    // A new *optional* parameter is additive; a new required one rejects
    // every call the consumer already makes.
    yield ContractChange(
      severity: now['required'] == true
          ? ContractSeverity.breaking
          : ContractSeverity.compatible,
      route: key,
      description: now['required'] == true
          ? "new required parameter '$name'"
          : "new optional parameter '$name'",
    );
  }
}

/// Routes keyed by `METHOD path`, which is what a caller actually depends on —
/// the controller and handler names are the producer's business.
Map<String, Map<String, dynamic>> _byKey(Map<String, dynamic> manifest) {
  final routes = (manifest['routes'] as List<dynamic>?) ?? const [];

  return {
    for (final entry in routes.cast<Map<String, dynamic>>())
      '${entry['method']} ${entry['path']}': entry,
  };
}

Map<String, Map<String, dynamic>> _paramsByName(Map<String, dynamic> route) {
  final params = (route['params'] as List<dynamic>?) ?? const [];

  return {
    for (final param in params.cast<Map<String, dynamic>>())
      // Keyed by the wire name, not the Dart parameter name: renaming the
      // Dart argument while keeping `@Query('id')` changes nothing a caller
      // can observe.
      '${param['binding'] ?? param['name']}': param,
  };
}
