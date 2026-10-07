import 'dart:io';
import 'api_client.dart';
import 'api_config.dart';

class MediaApiService {
  static final MediaApiService _instance = MediaApiService._internal();
  factory MediaApiService() => _instance;
  MediaApiService._internal();

  final ApiClient _client = ApiClient();

  /// Tải ảnh lên Cloudinary qua Server Backend (hỗ trợ kiểm tra Magic Bytes chống mã độc)
  Future<String> uploadImage(File file, {String? folder}) async {
    final fields = <String, String>{};
    if (folder != null && folder.isNotEmpty) {
      fields['folder'] = folder;
    }

    final response = await _client.uploadFile(
      ApiConfig.mediaUpload,
      file: file,
      fileField: 'file',
      fields: fields,
    );

    final data = response['data'] ?? response;
    final url = data['url'] ?? data['secure_url'] ?? data['fileUrl'];
    if (url != null) {
      return url.toString();
    }
    throw ApiException(
      message: 'Không nhận được đường dẫn ảnh từ máy chủ',
      statusCode: 500,
    );
  }

  /// Lấy Presigned Signature để upload trực tiếp lên Cloudinary
  Future<Map<String, dynamic>> getSignature({String? folder}) async {
    final query = folder != null ? {'folder': folder} : null;
    final response = await _client.get(ApiConfig.mediaSignature, queryParams: query);
    return response['data'] ?? response;
  }
}
