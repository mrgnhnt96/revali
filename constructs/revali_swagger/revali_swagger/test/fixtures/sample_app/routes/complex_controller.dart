import 'package:revali_router/revali_router.dart';
import 'package:revali_swagger_annotations/revali_swagger_annotations.dart';
import 'package:swagger_sample_app/models/complex_model.dart';

@Controller('complex')
@ApiTag('complex')
class ComplexController {
  @Get()
  @ApiSummary('Get a complex model')
  Future<ComplexModel> getComplex() async => throw UnimplementedError();

  @Post()
  @StatusCode(201)
  @ApiSummary('Create a complex model')
  Future<ComplexModel> createComplex(@Body() ComplexModel body) async =>
      throw UnimplementedError();
}
