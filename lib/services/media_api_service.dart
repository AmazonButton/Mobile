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
    final url =
        data['secureUrl'] ??
        data['secure_url'] ??
        data['url'] ??
        data['fileUrl'];
    final uri = Uri.tryParse(url?.toString() ?? '');
    if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
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
    final response = await _client.get(
      ApiConfig.mediaSignature,
      queryParams: query,
    );
    return response['data'] ?? response;
  }
}
