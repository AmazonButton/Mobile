import '../models/identity_verification.dart';
import '../models/page_result.dart';
import 'api_client.dart';

class IdentityVerificationService {
  static const _path = '/identity-verifications/sessions';
  final _api = ApiClient();
  Future<PageResult<IdentityVerification>> list({int page = 1}) async =>
      PageResult.fromResponse(
        await _api.get(_path, queryParams: {'page': page, 'pageSize': 20}),
        IdentityVerification.fromJson,
        requestedPage: page,
        pageSize: 20,
      );
  Future<IdentityVerification> create() async {
    final response = await _api.post(_path);
    return IdentityVerification.fromJson(
      Map<String, dynamic>.from(response['data']),
    );
  }

  Future<IdentityVerification> get(String id) async {
    final response = await _api.get('$_path/$id');
    return IdentityVerification.fromJson(
      Map<String, dynamic>.from(response['data']),
    );
  }

  Future<IdentityVerification> checkDecision(String id) async {
    await _api.get('$_path/$id/decision');
    // The decision endpoint may return the pre-sync status. Read the saved session.
    return get(id);
  }
}
