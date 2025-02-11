import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
      port: appConfig.port,
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
  final int port;
  final String? prefix;
}

final class _AppConfig extends AppConfig {
  const _AppConfig() : super.defaultApp();
}

(String? host, int? port, String? prefix) _getConfigs(ClassElement element) {
  final session = element.library.session;
  final libraryResult = session.getParsedLibraryByElement(element.library);

  var foundHost = false;
  var foundPort = false;
  var foundPrefix = false;

  String? host;
  int? port;
  String? prefix;

  if (libraryResult is ParsedLibraryResult) {
    // Find the constructor declaration from the parsed unit
    for (final unit in libraryResult.units) {
      for (final declaration in unit.unit.declarations) {
        if (declaration is ClassDeclaration &&
            declaration.name.lexeme == element.name) {
          for (final member in declaration.members) {
            if (member is ConstructorDeclaration) {
              for (final initializer in member.initializers) {
                if (initializer is SuperConstructorInvocation) {
                  // Extract arguments
                  for (final arg in initializer.argumentList.arguments) {
                    if (arg is NamedExpression) {
                      if (arg.name.label.name == 'host') {
                        host = switch (arg.expression) {
                          final StringLiteral e => e.stringValue,
                          _ => null,
                        };
                        foundHost = true;
                      } else if (arg.name.label.name == 'port') {
                        port = switch (arg.expression) {
                          final IntegerLiteral e => e.value,
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

                  if (foundHost && foundPort) {
                    return (host, port, prefix);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  return (null, null, null);
}
