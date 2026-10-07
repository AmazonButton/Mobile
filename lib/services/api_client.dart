import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';


class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? errorCode;
  final dynamic details;

  ApiException({
    required this.message,
    required this.statusCode,
    this.errorCode,
    this.details,
  });

  @override
  String toString() => 'ApiException: [$statusCode] $message (code: $errorCode)';
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _httpClient = http.Client();

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  void setTokens({required String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    if (refreshToken != null) {
      _refreshToken = refreshToken;
    }
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${ApiConfig.baseUrl}$cleanPath';
    final uri = Uri.parse(fullUrl);

    if (queryParams == null || queryParams.isEmpty) {
      return uri;
    }

    final queryMap = <String, String>{};
    queryParams.forEach((key, value) {
      if (value != null) {
        queryMap[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: queryMap);
  }

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      jsonBody = null;
    }

    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (jsonBody is Map<String, dynamic>) {
        return jsonBody;
      }
      return {'success': true, 'data': jsonBody};
    }

    // Handle error envelope from NestJS
    String errorMessage = 'Yêu cầu thất bại (HTTP $statusCode)';
    String? errorCode;
    dynamic details;

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody['message'] is String) {
        errorMessage = jsonBody['message'];
      } else if (jsonBody['message'] is List) {
        errorMessage = (jsonBody['message'] as List).join(', ');
      }
      errorCode = jsonBody['errorCode']?.toString();
      details = jsonBody['data'] ?? jsonBody['details'];
    }

    throw ApiException(
      message: errorMessage,
      statusCode: statusCode,
      errorCode: errorCode,
      details: details,
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    try {
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(headers))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}). Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Lỗi truyền tải mạng: ${e.toString()}',
        statusCode: -1,
      );
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = await _httpClient
          .post(uri, headers: _buildHeaders(headers), body: encodedBody)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}). Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Lỗi gửi yêu cầu: ${e.toString()}',
        statusCode: -1,
      );
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = await _httpClient
          .put(uri, headers: _buildHeaders(headers), body: encodedBody)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}). Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Lỗi cập nhật: ${e.toString()}',
        statusCode: -1,
      );
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = await _httpClient
          .patch(uri, headers: _buildHeaders(headers), body: encodedBody)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}). Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Lỗi cập nhật trạng thái: ${e.toString()}',
        statusCode: -1,
      );
    }
  }

  Future<dynamic> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final encodedBody = body != null ? jsonEncode(body) : null;
    try {
      final response = await _httpClient
          .delete(uri, headers: _buildHeaders(headers), body: encodedBody)
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Không thể kết nối đến máy chủ (${ApiConfig.baseUrl}). Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Lỗi xóa dữ liệu: ${e.toString()}',
        statusCode: -1,
      );
    }
  }

  Future<dynamic> uploadFile(
    String path, {
    required File file,
    String fileField = 'file',
    Map<String, String>? fields,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);

    if (_accessToken != null && _accessToken!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $_accessToken';
    }

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final multipartFile = await http.MultipartFile.fromPath(fileField, file.path);
    request.files.add(multipartFile);

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        message: 'Không thể tải tệp lên máy chủ. Vui lòng kiểm tra kết nối mạng.',
        statusCode: 0,
        errorCode: 'NETWORK_ERROR',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Lỗi tải tệp: ${e.toString()}',
        statusCode: -1,
      );
    }
  }
}
