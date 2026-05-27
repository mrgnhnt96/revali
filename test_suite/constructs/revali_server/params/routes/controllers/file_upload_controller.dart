import 'package:revali_router/revali_router.dart';

@Controller('file')
class FileUploadController {
  const FileUploadController();

  @Post()
  Map<String, dynamic> uploadFile(@Body() Map<String, dynamic> data) {
    final file = data['file'] as Map<String, dynamic>;

    return {
      'filename': file['filename'],
      'size': (file['bytes'] as List).length,
      'content': file['content'],
      'is_awesome': data['is_awesome'],
      'count': data['count'],
    };
  }

  @Post('raw')
  Map<String, dynamic> uploadRaw(@Body() List<int> bytes) {
    return {
      'size': bytes.length,
      'content': String.fromCharCodes(bytes),
    };
  }

  @Post('stream')
  Future<Map<String, dynamic>> uploadStream(
    @Body() Stream<List<int>> bytes,
  ) async {
    final chunks = await bytes.toList();
    final size = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);

    return {'size': size};
  }
}
