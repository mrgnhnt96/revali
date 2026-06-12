import 'package:revali_router/revali_router.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';
import 'package:swagger_sample_app/models/secret_data.dart';
import 'package:swagger_sample_app/models/user.dart';

@Controller('users')
@ApiTag('users')
class UsersController {
  @Get()
  @ApiSummary('List all users')
  Future<List<User>> listUsers(@Query() int? limit) async =>
      throw UnimplementedError();

  @Get(':id')
  Future<User> getUser(@Param() String id) async => throw UnimplementedError();

  @Get('search')
  @ApiSummary('Search users by query')
  Future<List<User>> searchUsers(@Body(['q']) String query) async =>
      throw UnimplementedError();

  @Post()
  @StatusCode(201)
  @ApiSummary('Create a user')
  Future<User> createUser(@Body() User body) async =>
      throw UnimplementedError();

  @Delete(':id')
  @StatusCode(204)
  @ApiHidden()
  Future<SecretData> deleteUser(@Param() String id) async =>
      throw UnimplementedError();
}
