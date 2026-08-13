// ignore_for_file: unnecessary_parenthesis

import 'dart:io';
import 'dart:isolate';

import 'package:code_builder/code_builder.dart';
import 'package:revali/server/converters/server_server.dart';
import 'package:revali/server/makers/creators/create_app.dart';
import 'package:revali/server/makers/creators/create_bind_server.dart';
import 'package:revali/server/makers/creators/create_class.dart';
import 'package:revali/server/makers/creators/create_dependency_injection.dart';
import 'package:revali/server/makers/creators/create_mimic.dart';
import 'package:revali/server/makers/creators/create_modifier_args.dart';
import 'package:revali/server/makers/creators/create_routes_variable.dart';
import 'package:revali/server/makers/utils/try_catch.dart';
import 'package:revali/server/makers/utils/type_extensions.dart';
import 'package:revali/server/models/options.dart';
import 'package:revali_router/revali_router.dart' hide AllowOrigins, Method;

String serverFile(
  ServerServer server,
  String Function(Spec) formatter, {
  required Options options,
}) {
  final imports = [
    if (options.ignoreLints case final lints when lints.isNotEmpty)
      "// ignore_for_file: ${options.ignoreLints.join(', ')}\n",
    "import 'dart:io';",
    "import 'dart:async';",
    "import 'dart:isolate';",
    '',
    "import 'package:path/path.dart' as p;",
    for (final imprt in {
      if (server.context.mode.isDebug)
        'package:revali_construct/revali_construct.dart',
      'package:revali_router/revali_router.dart',
      ...server.packageImports(),
    })
      "import '$imprt';",
    '',
    for (final imprt in {...server.pathImports()}) "import '../../$imprt';",
  ];

  final app = server.app;
  if (app == null) {
    throw Exception('No app found');
  }

  final isDebug = server.context.mode.isDebug;

  final main = Method(
    (b) => b
      ..name = 'main'
      ..returns = refer('void')
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = 'args'
            ..type = refer('List<String>'),
        ),
      )
      ..body = Block.of([
        if (isDebug)
          refer('hotReload').call([
            Method(
              (b) => b
                ..lambda = true
                ..body = refer(
                  'createServer',
                ).call([literalNull, refer('args')]).code,
            ).closure,
          ]).statement
        else
          refer('createServer').call([literalNull, refer('args')]).statement,
      ]),
  );

  // Worker entry sets a per-isolate flag so createServer keeps its positional
  // signature (used by tests as createServer(httpServer)), and stashes the
  // port the parent uses to tell this isolate to drain.
  final workerEntrypoint = Method(
    (b) => b
      ..name = '_revaliWorkerMain'
      ..returns = refer('void')
      ..requiredParameters.add(
        Parameter(
          (p) => p
            ..name = 'boot'
            ..type = refer('List<Object>'),
        ),
      )
      ..body = const Code('''
_revaliIsWorker = true;
_revaliWorkerRegistration = boot[1] as SendPort;
createServer(null, (boot[0] as List).cast<String>());
'''),
  );

  final createServer = Method(
    (b) => b
      ..name = 'createServer'
      ..returns = TypeReference(
        (p) => p
          ..symbol = (Future).name
          ..types.add(refer((HttpServer).name)),
      )
      ..modifier = MethodModifier.async
      ..optionalParameters.addAll([
        Parameter(
          (e) => e
            ..name = 'providedServer'
            ..named = false
            ..type = refer('${(HttpServer).name}?'),
        ),
        Parameter(
          (e) => e
            ..name = 'rawArgs'
            ..named = false
            ..defaultTo = const Code('const []')
            ..type = refer('List<String>'),
        ),
      ])
      ..body = Block.of([
        declareFinal('isWorker').assign(refer('_revaliIsWorker')).statement,
        refer('_revaliIsWorker').assign(literalFalse).statement,
        declareFinal(
          'workerRegistration',
        ).assign(refer('_revaliWorkerRegistration')).statement,
        refer('_revaliWorkerRegistration').assign(literalNull).statement,
        declareFinal('args')
            .assign(
              refer((Args).name).newInstanceNamed('parse', [refer('rawArgs')]),
            )
            .statement,
        declareFinal(
          'app',
          type: refer((AppConfig).name),
        ).assign(createApp(app)).statement,
        const Code('''
if (!isWorker && providedServer == null && app.workers > 1) {
  for (final isolate in _revaliWorkerIsolates) {
    isolate.kill(priority: Isolate.immediate);
  }
  _revaliWorkerIsolates = <Isolate>[];
  // Also drops the previous generation's command ports, which a hot reload
  // would otherwise accumulate on every restart.
  final registration = _revaliWorkerFleet.open();
  for (var i = 1; i < app.workers; i++) {
    _revaliWorkerIsolates.add(
      await Isolate.spawn(
        _revaliWorkerMain,
        <Object>[rawArgs, registration],
      ),
    );
  }
}
'''),
        refer('app')
            .property('runStartup')
            .call([
              Method(
                (b) => b
                  ..modifier = MethodModifier.async
                  ..body = Block.of([
                    declareFinal(
                      'server',
                      late: true,
                      type: refer('HttpServer'),
                    ).statement,
                    tryCatch(
                      refer('server')
                          .assign(
                            bindServerCall(
                              app: refer('app'),
                              providedServer: refer('providedServer'),
                              shared: isDebug
                                  ? literalTrue
                                  : refer('app')
                                        .property('workers')
                                        .greaterThan(literalNum(1))
                                        .or(refer('isWorker')),
                            ).awaited,
                          )
                          .statement,
                      Block.of([
                        refer('print').call([
                          literalString(r'Failed to bind server:\n$e'),
                        ]).statement,
                        refer('exit').call([literalNum(1)]).statement,
                      ]),
                    ),
                    const Code('\n'),
                    ...createDependencyInjection(server),
                    const Code('\n'),
                    ...createRoutesVariable(server),
                    const Code('\n'),
                    Block.of([
                      const Code('if ('),
                      refer('app').property('prefix').code,
                      const Code(' case'),
                      declareFinal('prefix?').code,
                      const Code(' when '),
                      refer('prefix').property('isNotEmpty').code,
                      const Code(') {'),
                      refer('_routes')
                          .assign(
                            literalList([
                              refer((Route).name).newInstance(
                                [refer('prefix')],
                                {'routes': refer('_routes')},
                              ),
                            ]),
                          )
                          .statement,
                      const Code('}'),
                    ]),
                    const Code('\n'),
                    // Declared before the router so the readiness probe can
                    // read the drain flag off it. The probe has to reflect
                    // the *current* shutdown state, so it closes over
                    // `inFlight` rather than a value read at startup.
                    declareFinal('inFlight')
                        .assign(refer((InFlightRequests).name).newInstance([]))
                        .statement,
                    const Code('\n'),
                    declareFinal('router')
                        .assign(
                          refer((Router).name).newInstance([], {
                            if (server.context.mode.isNotRelease)
                              'debug': literalTrue,
                            'inspect': refer('bool')
                                .property('fromEnvironment')
                                .call([literalString('REVALI_INSPECT')]),
                            'inspectLogPath': refer('String')
                                .property('fromEnvironment')
                                .call(
                                  [literalString('REVALI_INSPECT_LOG')],
                                  {'defaultValue': literalString('')},
                                ),
                            'routes': literalList([
                              refer('_routes').spread,
                              refer('public').spread,
                              // Added here rather than inside the prefix
                              // wrapping above, so probes answer on the bare
                              // paths an orchestrator is configured with.
                              refer('healthRoutes').call([], {
                                'settings': refer('app').property('health'),
                                'isDraining': Method(
                                  (b) => b
                                    ..lambda = true
                                    ..body = refer(
                                      'inFlight',
                                    ).property('isDraining').code,
                                ).closure,
                              }).spread,
                            ]),
                            if (app.observers.hasObservers)
                              'observers': literalList([
                                if (app.observers.types.expand((e) => e.types)
                                    case final observers
                                    when observers.isNotEmpty)
                                  for (final observer in observers)
                                    createClass(observer),
                                if (app.observers.mimics case final mimics
                                    when mimics.isNotEmpty)
                                  for (final type in mimics) createMimic(type),
                              ]),
                            'reflects': refer('reflects'),
                            'defaultResponses': refer(
                              'app',
                            ).property('defaultResponses'),
                            'trustedProxy': refer(
                              'app',
                            ).property('trustedProxy'),
                            'compression': refer('app').property('compression'),
                            // Gives every request its own scope, so
                            // `registerRequestScoped` dependencies are built
                            // once per request and disposed when it ends.
                            'di': refer('di'),
                            if (server.app case final app?
                                when app.globalRouteAnnotations.hasAnnotations)
                              'globalComponents':
                                  refer(
                                    (LifecycleComponentsImpl).name,
                                  ).newInstance([], {
                                    ...createModifierArgs(
                                      annotations: app.globalRouteAnnotations,
                                    ),
                                  }),
                          }),
                        )
                        .statement,
                    const Code('\n'),
                    refer('handleRouterRequests')
                        .call(
                          [
                            refer('server'),
                            refer('router'),
                            refer('router').property('close'),
                          ],
                          {'inFlight': refer('inFlight')},
                        )
                        .property('ignore')
                        .call([])
                        .statement,
                    const Code('\n'),
                    // Only a server this function created and owns may install
                    // process-wide signal handlers. A provided server belongs
                    // to the caller (tests pass a TestServer), and a worker
                    // isolate is told when to drain by the parent instead.
                    const Code(r'''
Future<void> drainThisIsolate(Duration drainDelay) async {
  await shutdownServer(
    server: server,
    inFlight: inFlight,
    timeout: app.shutdownTimeout,
    drainDelay: drainDelay,
    onStopped: app.onServerStopped,
    log: print,
  );
  router.close();
}

if (isWorker) {
  // Every isolate binds the same port and keeps its own in-flight set, so a
  // worker has to drain itself. It never watches signals: the parent waits
  // for the reply before exiting, and exit() would take the whole process
  // down with requests still running here.
  if (workerRegistration case final registration?) {
    listenForDrainCommands(registration, drainThisIsolate);
  }
} else if (providedServer == null && app.handleShutdownSignals) {
  listenForShutdown((signal) async {
    print('Received $signal, shutting down...');
    // SIGINT is a human at a terminal who wants the process gone now.
    // SIGTERM is an orchestrator, which is who the delay exists for.
    final drainDelay = signal == ProcessSignal.sigterm
        ? app.drainDelay
        : Duration.zero;
    // Concurrently, so every isolate flags its own readiness at once and
    // probes report 503 across the whole fleet rather than only whichever
    // isolate happened to handle the signal.
    await Future.wait([
      _revaliWorkerFleet.drainAll(
        drainDelay: drainDelay,
        timeout: drainDelay + app.shutdownTimeout,
        log: print,
      ),
      drainThisIsolate(drainDelay),
    ]);
    exit(0);
  });
}
'''),
                    const Code('\n'),
                    const Code('if (!isWorker) {'),
                    refer('app').property('onServerStarted').call([
                      refer('server'),
                    ]).statement,
                    const Code('}'),
                    const Code('\n'),
                    refer('server').returned.statement,
                  ]),
              ).closure,
            ])
            .returned
            .statement,
      ]),
  );

  final parts = <Spec>[
    declareVar(
      '_revaliWorkerIsolates',
      type: TypeReference(
        (t) => t
          ..symbol = 'List'
          ..types.add(refer((Isolate).name)),
      ),
    ).assign(literalList([], refer((Isolate).name))).statement,
    declareVar(
      '_revaliIsWorker',
      type: refer('bool'),
    ).assign(literalFalse).statement,
    declareFinal(
      '_revaliWorkerFleet',
      type: refer((WorkerFleet).name),
    ).assign(refer((WorkerFleet).name).newInstance([])).statement,
    declareVar(
      '_revaliWorkerRegistration',
      type: refer('${(SendPort).name}?'),
    ).statement,
    createBindServerMethod(),
    workerEntrypoint,
    main,
    createServer,
  ];

  final content = parts.map(formatter).join('\n');

  return '''
${imports.join('\n')}
$content''';
}
