import 'package:revali_router/revali_router.dart';
import 'package:revali_server_meta_reflect_test/components/user_json_sanitizer.dart';
import 'package:revali_server_meta_reflect_test/domain/silly_name.dart';
import 'package:revali_server_meta_reflect_test/domain/user.dart';

@Controller('meta-reflect')
class MetaReflectController {
  const MetaReflectController();

  @UserJsonSanitizer()
  @Get('user-data')
  User userData() {
    return const User(name: 'Ganondorf', password: 'i-hate-hyrule');
  }

  @SillyName('Happy Mask')
  @Get('route-data')
  String routeData(Meta meta) {
    final sillyName = meta.get<SillyName>()?.single;

    return sillyName?.name ?? 'No silly name';
  }
}
