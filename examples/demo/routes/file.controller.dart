import 'package:revali_annotations/revali_annotations.dart';
import 'package:revali_router_annotations/revali_router_annotations.dart';

@Controller('file')
class FileUploader {
  const FileUploader();

  @Post(':id')
  void uploadFile(
    @Param('hi', ParamPipe) String id,
  ) {
    // Upload file
  }
}

class ParamPipe extends Pipe<String, String> {
  @override
  String transform(String value, PipeContext context) {
    return value;
  }
}
