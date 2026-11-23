import 'api_client.dart';
import 'api_config.dart';

/// Backend API service dedicated to SYSTEM_STAFF (Nhân viên hệ thống) operations:
/// - Platform device warehouse, batch generation, bulk import, store allocation & lifecycle ops
/// - Global & store device templates + bulk deploy (up to 100 buttons)
/// - Technical warranty ticket inspection, 1-1 swap, lock device, resolve & reject
/// - Rental return queue inspection & receipt confirmation
class SystemStaffApiService {
  static final SystemStaffApiService _instance =
      SystemStaffApiService._internal();
  factory SystemStaffApiService() => _instance;
  SystemStaffApiService._internal();

  final ApiClient _client = ApiClient();

  Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {'data': raw};
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    final source = raw is Map ? (raw['data'] ?? raw['items']) : raw;
    if (source is List) {
      return source
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _extractPagination(dynamic raw, int count) {
    final res = _asMap(raw);
    final pag = res['pagination'] ?? res['meta'];
    if (pag is Map) {
      return Map<String, dynamic>.from(pag);
    }
    return {'page': 1, 'totalPages': 1, 'totalItems': count};
  }

  // ==================== PUBLIC STORES & PRODUCTS ====================

  Future<List<Map<String, dynamic>>> listStores() async {
    final res = await _client.get(
      ApiConfig.stores,
      queryParams: {'page': 1, 'pageSize': 100},
    );
    return _extractList(res);
  }

  Future<List<Map<String, dynamic>>> listProducts({String? storeId}) async {
    final query = <String, dynamic>{'page': 1, 'pageSize': 100};
    if (storeId != null && storeId.isNotEmpty) query['storeId'] = storeId;
    final res = await _client.get(ApiConfig.products, queryParams: query);
    return _extractList(res);
  }

  // ==================== DEVICES WAREHOUSE & OPS ====================

  Future<Map<String, dynamic>> getFleetStats() async {
    final res = await _client.get(ApiConfig.devicesFleetStats);
    final data = res['data'];
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<({List<Map<String, dynamic>> items, Map<String, dynamic> pagination})>
  listDevices({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? custodyStoreId,
    String? inventoryState,
    bool allocatedOnly = false,
  }) async {
    final query = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (custodyStoreId != null && custodyStoreId.isNotEmpty) {
      query['custodyStoreId'] = custodyStoreId;
    }
    if (inventoryState != null && inventoryState.isNotEmpty) {
      query['inventoryState'] = inventoryState;
    }
    if (allocatedOnly) query['allocatedOnly'] = 'true';

    final res = await _client.get(ApiConfig.devices, queryParams: query);
    final items = _extractList(res);
    return (items: items, pagination: _extractPagination(res, items.length));
  }

  Future<({List<Map<String, dynamic>> items, Map<String, dynamic> pagination})>
  listUnassignedDevices({int page = 1, int pageSize = 25, String? search}) async {
    final query = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final res = await _client.get(
      ApiConfig.devicesUnassigned,
      queryParams: query,
    );
    final items = _extractList(res);
    return (items: items, pagination: _extractPagination(res, items.length));
  }

  Future<Map<String, dynamic>> registerDevice(Map<String, dynamic> body) async {
    return _asMap(await _client.post(ApiConfig.devices, body: body));
  }

  Future<Map<String, dynamic>> bulkImportDevices({
    required List<Map<String, dynamic>> rows,
    String? storeId,
  }) async {
    return _asMap(
      await _client.post(
        ApiConfig.devicesBulkImport,
        body: {
          'rows': rows,
          if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> batchGenerateDevices({
    required String prefix,
    required int count,
    String? model,
  }) async {
    return _asMap(
      await _client.post(
        ApiConfig.devicesBatchGenerate,
        body: {
          'prefix': prefix.trim().toUpperCase(),
          'count': count,
          if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
        },
      ),
    );
  }

  Future<Map<String, dynamic>> lookupCode(String code) async {
    final res = _asMap(
      await _client.post(
        ApiConfig.devicesLookupCode,
        body: {'code': code.trim()},
      ),
    );
    final data = res['data'];
    return data is Map ? Map<String, dynamic>.from(data) : res;
  }

  Future<Map<String, dynamic>> allocateToStore({
    required String storeId,
    required List<String> deviceIds,
  }) async {
    return _asMap(
      await _client.post(
        ApiConfig.devicesAllocateStore,
        body: {'storeId': storeId, 'deviceIds': deviceIds},
      ),
    );
  }

  Future<Map<String, dynamic>> getStoreInventory(String storeId) async {
    final res = _asMap(
      await _client.get(
        ApiConfig.deviceStoreInventory(Uri.encodeComponent(storeId)),
      ),
    );
    final data = res['data'];
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<Map<String, dynamic>> enableDevice(String id) async =>
      _asMap(await _client.post(ApiConfig.deviceEnable(Uri.encodeComponent(id))));

  Future<Map<String, dynamic>> disableDevice(String id) async =>
      _asMap(await _client.post(ApiConfig.deviceDisable(Uri.encodeComponent(id))));

  Future<Map<String, dynamic>> updateDeviceStatus(
    String id,
    String status,
  ) async => _asMap(
    await _client.patch(
      ApiConfig.deviceStatus(Uri.encodeComponent(id)),
      body: {'status': status},
    ),
  );

  Future<Map<String, dynamic>> toggleActive(String id, String status) async =>
      _asMap(
        await _client.patch(
          ApiConfig.deviceToggleActive(Uri.encodeComponent(id)),
          body: {'status': status},
        ),
      );

  Future<Map<String, dynamic>> pairDevice(String id, String code) async =>
      _asMap(
        await _client.post(
          ApiConfig.devicePair(Uri.encodeComponent(id)),
          body: {'code': code.trim(), 'pairingToken': code.trim()},
        ),
      );

  Future<Map<String, dynamic>> repairDevice(String id) async =>
      _asMap(await _client.post(ApiConfig.deviceRepair(Uri.encodeComponent(id))));

  Future<Map<String, dynamic>> claimDevice(
    String deviceId,
    String claimCode,
  ) async => _asMap(
    await _client.post(
      ApiConfig.devicesClaim,
      body: {'deviceId': deviceId.trim(), 'claimCode': claimCode.trim()},
    ),
  );

  Future<Map<String, dynamic>> assignDevice(
    String id, {
    String? storeId,
    String? customerId,
  }) async => _asMap(
    await _client.post(
      ApiConfig.deviceAssign(Uri.encodeComponent(id)),
      body: {
        if (storeId != null && storeId.isNotEmpty) 'storeId': storeId,
        if (customerId != null && customerId.isNotEmpty)
          'customerId': customerId,
      },
    ),
  );

  Future<Map<String, dynamic>> assignProduct(
    String id, {
    required String productId,
    int quantity = 1,
    String? customName,
  }) async => _asMap(
    await _client.post(
      ApiConfig.deviceAssignProduct(Uri.encodeComponent(id)),
      body: {
        'productId': productId,
        'quantity': quantity,
        if (customName != null && customName.trim().isNotEmpty)
          'customName': customName.trim(),
      },
    ),
  );

  Future<Map<String, dynamic>> removeProduct(String id) async => _asMap(
    await _client.delete(ApiConfig.deviceRemoveProduct(Uri.encodeComponent(id))),
  );

  Future<Map<String, dynamic>> updateBehavior(
    String id, {
    required String clickBehavior,
    int? doubleClickWindowMs,
    int? holdDurationMs,
  }) async => _asMap(
    await _client.put(
      ApiConfig.deviceBehavior(Uri.encodeComponent(id)),
      body: {
        'clickBehavior': clickBehavior,
        if (doubleClickWindowMs != null)
          'doubleClickWindowMs': doubleClickWindowMs,
        if (holdDurationMs != null) 'holdDurationMs': holdDurationMs,
      },
    ),
  );

  Future<Map<String, dynamic>> updateBattery(
    String id,
    int batteryLevel,
  ) async => _asMap(
    await _client.patch(
      ApiConfig.deviceBattery(Uri.encodeComponent(id)),
      body: {'batteryLevel': batteryLevel},
    ),
  );

  Future<List<Map<String, dynamic>>> getTelemetry(String id) async {
    final res = _asMap(
      await _client.get(ApiConfig.deviceTelemetry(Uri.encodeComponent(id))),
    );
    final raw = res['data'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map) return [Map<String, dynamic>.from(raw)];
    return const [];
  }

  Future<List<Map<String, dynamic>>> getAuditLogs(String id) async {
    final res = await _client.get(
      ApiConfig.deviceAuditLogs(Uri.encodeComponent(id)),
    );
    return _extractList(res);
  }

  Future<Map<String, dynamic>> extendWarranty(String id, int months) async =>
      _asMap(
        await _client.patch(
          ApiConfig.deviceExtendWarranty(Uri.encodeComponent(id)),
          body: {'months': months},
        ),
      );

  Future<Map<String, dynamic>> factoryReset(String id) async => _asMap(
    await _client.post(ApiConfig.deviceFactoryReset(Uri.encodeComponent(id))),
  );

  Future<Map<String, dynamic>> changeWifi(
    String id, {
    required String ssid,
    required String password,
  }) async => _asMap(
    await _client.post(
      ApiConfig.deviceChangeWifi(Uri.encodeComponent(id)),
      body: {'ssid': ssid.trim(), 'password': password},
    ),
  );

  Future<Map<String, dynamic>> deleteDevice(String id) async => _asMap(
    await _client.delete(ApiConfig.deviceDetail(Uri.encodeComponent(id))),
  );

  // ==================== DEVICE TEMPLATES ====================

  Future<List<Map<String, dynamic>>> listTemplates() async {
    final res = await _client.get(ApiConfig.deviceTemplates);
    return _extractList(res);
  }

  Future<Map<String, dynamic>> createTemplate(
    Map<String, dynamic> body,
  ) async => _asMap(await _client.post(ApiConfig.deviceTemplates, body: body));

  Future<Map<String, dynamic>> updateTemplate(
    String id,
    Map<String, dynamic> body,
  ) async => _asMap(
    await _client.patch(
      ApiConfig.deviceTemplateDetail(Uri.encodeComponent(id)),
      body: body,
    ),
  );

  Future<Map<String, dynamic>> deleteTemplate(String id) async => _asMap(
    await _client.delete(ApiConfig.deviceTemplateDetail(Uri.encodeComponent(id))),
  );

  Future<Map<String, dynamic>> deployTemplate(
    String id,
    Map<String, dynamic> body,
  ) async => _asMap(
    await _client.post(
      ApiConfig.deviceTemplateDeploy(Uri.encodeComponent(id)),
      body: body,
    ),
  );

  // ==================== TECHNICAL WARRANTY ====================

  Future<({List<Map<String, dynamic>> items, Map<String, dynamic> pagination})>
  listWarrantyTickets({
    String? status,
    String? faultGroup,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (faultGroup != null && faultGroup.isNotEmpty) {
      query['faultGroup'] = faultGroup;
    }
    final res = await _client.get(
      ApiConfig.warrantyTickets,
      queryParams: query,
    );
    final items = _extractList(res);
    return (items: items, pagination: _extractPagination(res, items.length));
  }

  Future<Map<String, dynamic>> getWarrantyTicket(String id) async {
    final res = _asMap(
      await _client.get(
        ApiConfig.warrantyTicketDetail(Uri.encodeComponent(id)),
      ),
    );
    final data = res['data'];
    return data is Map ? Map<String, dynamic>.from(data) : res;
  }

  Future<Map<String, dynamic>> createWarrantyTicket(
    Map<String, dynamic> body,
  ) async => _asMap(await _client.post(ApiConfig.warrantyTickets, body: body));

  Future<Map<String, dynamic>> approveSwap(
    String id, {
    String? replacementDeviceId,
    String? adminNote,
  }) async => _asMap(
    await _client.patch(
      ApiConfig.warrantyApproveSwap(Uri.encodeComponent(id)),
      body: {
        if (replacementDeviceId != null &&
            replacementDeviceId.trim().isNotEmpty)
          'replacementDeviceId': replacementDeviceId.trim(),
        if (adminNote != null && adminNote.trim().isNotEmpty)
          'adminNote': adminNote.trim(),
      },
    ),
  );

  Future<Map<String, dynamic>> lockWarrantyDevice(
    String id, {
    String? adminNote,
  }) async => _asMap(
    await _client.patch(
      ApiConfig.warrantyLockDevice(Uri.encodeComponent(id)),
      body: {
        if (adminNote != null && adminNote.trim().isNotEmpty)
          'adminNote': adminNote.trim(),
      },
    ),
  );

  Future<Map<String, dynamic>> resolveWarrantyTicket(
    String id, {
    String? adminNote,
  }) async => _asMap(
    await _client.patch(
      ApiConfig.warrantyResolve(Uri.encodeComponent(id)),
      body: {
        if (adminNote != null && adminNote.trim().isNotEmpty)
          'adminNote': adminNote.trim(),
      },
    ),
  );

  Future<Map<String, dynamic>> rejectWarrantyTicket(
    String id, {
    String? adminNote,
  }) async => _asMap(
    await _client.patch(
      ApiConfig.warrantyReject(Uri.encodeComponent(id)),
      body: {
        if (adminNote != null && adminNote.trim().isNotEmpty)
          'adminNote': adminNote.trim(),
      },
    ),
  );

  // ==================== RENTAL RETURNS ====================

  Future<({List<Map<String, dynamic>> items, Map<String, dynamic> pagination})>
  listReturnRequests({
    String status = 'PENDING_RECEIPT',
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final query = <String, dynamic>{
      'status': status,
      'page': page,
      'pageSize': pageSize,
    };
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final res = await _client.get(ApiConfig.rentalReturns, queryParams: query);
    final items = _extractList(res);
    return (items: items, pagination: _extractPagination(res, items.length));
  }

  Future<Map<String, dynamic>> confirmReturnReceipt(
    String returnId, {
    String? inspectionNote,
  }) async => _asMap(
    await _client.post(
      ApiConfig.rentalReturnConfirmReceipt(Uri.encodeComponent(returnId)),
      body: {
        if (inspectionNote != null && inspectionNote.trim().isNotEmpty)
          'inspectionNote': inspectionNote.trim(),
      },
    ),
  );
}
