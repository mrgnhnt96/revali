import 'package:file/file.dart';
import 'package:revali/clis/revali_runner/commands/ai/ai_command.dart';
import 'package:revali/clis/revali_runner/commands/build_command.dart';
import 'package:revali/clis/revali_runner/commands/compose_command.dart';
import 'package:revali/clis/revali_runner/commands/dev_command.dart';
import 'package:revali/clis/revali_runner/commands/doctor_command.dart';
import 'package:revali/clis/revali_runner/commands/routes_command.dart';
import 'package:revali/clis/revali_runner/commands/services_command.dart';
import 'package:revali/clis/revali_runner/commands/up_command.dart';
import 'package:revali/clis/shared/commands/revali_command_runner.dart';
import 'package:revali/handlers/construct_entrypoint_handler.dart';
import 'package:revali/server/cli/commands/create/create_command.dart';

class RevaliRunner extends RevaliCommandRunner {
  RevaliRunner({
    required super.logger,
    required String initialDirectory,
    required FileSystem fs,
  }) : super(
         'revali',
         'Revali code generator — commands: '
             'dev, build, routes, doctor, create, ai',
       ) {
    final entrypointHandler = ConstructEntrypointHandler(
      logger: logger,
      initialDirectory: initialDirectory,
      fs: fs,
    );

    addCommand(
      DevCommand(fs: fs, logger: logger, generator: entrypointHandler),
    );
    addCommand(
      BuildCommand(fs: fs, logger: logger, generator: entrypointHandler),
    );
    addCommand(
      RoutesCommand(fs: fs, logger: logger, generator: entrypointHandler),
    );
    addCommand(
      DoctorCommand(fs: fs, logger: logger, generator: entrypointHandler),
    );
    addCommand(ServicesCommand(fs: fs, logger: logger));
    addCommand(UpCommand(fs: fs, logger: logger));
    addCommand(ComposeCommand(fs: fs, logger: logger));
    addCommand(CreateCommand(fs: fs, logger: logger));
    addCommand(AiCommand(fs: fs, logger: logger));
  }
}
