import 'package:examples/repos/repo.dart';
import 'package:examples/utils/logger.dart';
import 'package:zora_core/zora_core.dart';

@Request()
class ThisRequest {
  const ThisRequest(this.repo, this.logger);

  final Repo repo;
  final Logger logger;

  @Get()
  getNewPerson({
    @Query('name') required String name,
    @Param('age') int? age,
  }) {
    return null;
  }
}
