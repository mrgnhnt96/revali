import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:revali_construct/revali_construct.dart';
import 'package:revali_core/revali_core.dart';

class ClientApp {
  const ClientApp({
    required this.host,
    required this.port,
    required this.prefix,
  });

  factory ClientApp.defaultConfig() {
    const appConfig = _AppConfig();
    return ClientApp(
      host: appConfig.host,
      port: '${appConfig.port}',
      prefix: appConfig.prefix,
    );
  }

  factory ClientApp.fromMeta(MetaAppConfig app) {
    final element = app.element;
    final defaultApp = ClientApp.defaultConfig();
    if (app.constructor == 'defaultApp' || element == null) {
      return defaultApp;
    }

    final (host, port, prefix) = _getConfigs(element);

    return ClientApp(
      host: host ?? defaultApp.host,
      port: port ?? defaultApp.port,
      prefix: prefix ?? defaultApp.prefix,
    );
  }

  final String host;
  final String port;
  final String? prefix;
}

final class _AppConfig extends AppConfig {
  const _AppConfig() : super.defaultApp();
}

(String? host, String? port, String? prefix) _getConfigs(ClassElement element) {
  final session = element.library.session;
  final libraryResult = session.getParsedLibraryByElement(element.library);

  var foundHost = false;
  var foundPort = false;
  var foundPrefix = false;

  String? host;
  String? port;
  String? prefix;

  const badResponse = (null, null, null);

  if (libraryResult is! ParsedLibraryResult) {
    return badResponse;
  }

  if (libraryResult.units.isEmpty) {
    return badResponse;
  }

  final [unit, ...] = libraryResult.units;

  final declaration = unit.unit.declarations.firstWhereOrNull(
    (e) => e is ClassDeclaration && e.name.lexeme == element.name,
  );

  if (declaration == null || declaration is! ClassDeclaration) {
    return badResponse;
  }

  final ctor = declaration.members.firstWhereOrNull(
    (e) => e is ConstructorDeclaration,
  );

  if (ctor == null || ctor is! ConstructorDeclaration) {
    return badResponse;
  }

  final initializer = ctor.initializers.firstWhereOrNull(
    (e) => e is SuperConstructorInvocation,
  );

  if (initializer == null || initializer is! SuperConstructorInvocation) {
    return badResponse;
  }

  for (final arg in initializer.argumentList.arguments) {
    if (arg is NamedExpression) {
      if (arg.name.label.name == 'host') {
        host = switch (arg.expression) {
          final StringLiteral e => e.stringValue,
          final InstanceCreationExpression e => '\${${e.toSource()}}',
          _ => null,
        };
        foundHost = true;
      } else if (arg.name.label.name == 'port') {
        port = switch (arg.expression) {
          final IntegerLiteral e => '${e.value}',
          final InstanceCreationExpression e => '\${${e.toSource()}}',
          _ => null,
        };
        foundPort = true;
      } else if (arg.name.label.name == 'prefix') {
        prefix = switch (arg.expression) {
          final StringLiteral e => e.stringValue,
          NullLiteral() => '',
          _ => null,
        };
        foundPrefix = true;
      }

      if (foundHost && foundPort && foundPrefix) {
        return (host, port, prefix);
      }
    }
  }

  return (host, port, prefix);
}
