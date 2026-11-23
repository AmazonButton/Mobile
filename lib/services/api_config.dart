class ApiConfig {
  ApiConfig._();

  /// Override with --dart-define=API_BASE_URL=... for a local backend.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-fae8.onrender.com/api/v1',
  );

  /// Active Base URL in runtime (can be customized for physical devices on local Wi-Fi)
  static String baseUrl = defaultBaseUrl;

  /// Update base URL at runtime (e.g. testing with physical device IP: http://192.168.1.50:3000/api/v1)
  static void setBaseUrl(String newUrl) {
    if (newUrl.endsWith('/')) {
      baseUrl = newUrl.substring(0, newUrl.length - 1);
    } else {
      baseUrl = newUrl;
    }
  }

  // Auth endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authGoogleLogin = '/auth/google-login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authCheckEmail = '/auth/check-email';
  static const String authCheckUsername = '/auth/check-username';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authVerifyEmail = '/auth/verify-email';
  static const String authResendVerification = '/auth/resend-verification';
  static const String authRegisterByPhone = '/auth/register-by-phone';
  static const String authLoginByPhone = '/auth/login-by-phone';

  // Devices endpoints
  static const String devices = '/devices';
  static const String devicesUnassigned = '/devices/unassigned';
  static const String devicesBulkImport = '/devices/bulk-import';
  static const String devicesBatchGenerate = '/devices/batch-generate';
  static const String devicesAllocateStore = '/devices/allocate-store';
  static const String devicesClaim = '/devices/claim';
  static const String devicesLookupCode = '/devices/lookup-code';
  static const String devicesConfigureByCode = '/devices/configure-by-code';
  static const String devicesFleetStats = '/devices/fleet/stats';
  static String deviceDetail(String id) => '/devices/$id';
  static String deviceStoreInventory(String storeId) =>
      '/devices/stores/$storeId/inventory';
  static String deviceCustomerConfig(String id) =>
      '/devices/$id/customer-config';
  static String deviceEnable(String id) => '/devices/$id/enable';
  static String deviceDisable(String id) => '/devices/$id/disable';
  static String deviceStatus(String id) => '/devices/$id/status';
  static String deviceToggleActive(String id) => '/devices/$id/toggle-active';
  static String deviceSimulatePress(String id) => '/devices/$id/simulate-press';
  static String deviceTelemetry(String id) => '/devices/$id/telemetry';
  static String deviceAuditLogs(String id) => '/devices/$id/audit-logs';
  static String devicePair(String id) => '/devices/$id/pair';
  static String deviceRepair(String id) => '/devices/$id/re-pair';
  static String deviceAssign(String id) => '/devices/$id/assign';
  static String deviceAssignProduct(String id) => '/devices/$id/assign-product';
  static String deviceRemoveProduct(String id) => '/devices/$id/product';
  static String deviceBehavior(String id) => '/devices/$id/behavior';
  static String deviceBattery(String id) => '/devices/$id/battery';
  static String deviceExtendWarranty(String id) =>
      '/devices/$id/extend-warranty';
  static String deviceFactoryReset(String id) => '/devices/$id/factory-reset';
  static String deviceChangeWifi(String id) => '/devices/$id/change-wifi';

  // Device templates endpoints
  static const String deviceTemplates = '/device-templates';
  static String deviceTemplateDetail(String id) => '/device-templates/$id';
  static String deviceTemplateDeploy(String id) =>
      '/device-templates/$id/deploy';

  // Warranty endpoints
  static const String warrantyTickets = '/warranty/tickets';
  static String warrantyTicketDetail(String id) => '/warranty/tickets/$id';
  static String warrantyApproveSwap(String id) =>
      '/warranty/tickets/$id/approve-swap';
  static String warrantyLockDevice(String id) =>
      '/warranty/tickets/$id/lock-device';
  static String warrantyResolve(String id) => '/warranty/tickets/$id/resolve';
  static String warrantyReject(String id) => '/warranty/tickets/$id/reject';

  // Rental returns endpoints
  static const String rentalReturns = '/rentals/returns';
  static String rentalReturnConfirmReceipt(String returnId) =>
      '/rentals/returns/$returnId/confirm-receipt';

  // Products endpoints
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';

  // Orders endpoints
  static const String orders = '/orders';
  static const String ordersQuickReorder = '/orders/quick-reorder';
  static const String ordersSimulatePress = '/orders/simulate-button-press';
  static const String ordersDeliveryQuote = '/orders/delivery-quote';
  static const String ordersDeliveryQueue = '/orders/delivery-queue';
  static String orderDetail(String id) => '/orders/$id';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static String orderStatus(String id) => '/orders/$id/status';
  static String productDiscounts(String productId) =>
      '/products/$productId/discounts';

  // Provisioning endpoints
  static const String provisioningSession = '/provisioning/session';
  static const String provisioningVerify = '/provisioning/verify';
  static String provisioningChangeWifi(String id) =>
      '/provisioning/devices/$id/change-wifi';

  // Media endpoints
  static const String mediaUpload = '/media/upload';
  static const String mediaSignature = '/media/signature';

  // Stores & Rentals & Wallet endpoints
  static const String stores = '/stores';
  static const String adminStores = '/admin/stores';
  static const String storeMe = '/stores/me';
  static String storeDetail(String id) => '/stores/$id';
  static const String rentalPackages = '/rentals/packages';
  static const String rentalOrder = '/rentals/order';
  static const String myRentals = '/rentals/my-rentals';
  static const String storeWallet = '/store/wallet';
  static const String storeWalletTransactions = '/store/wallet/transactions';
  static const String storeWalletWithdrawals = '/store/wallet/withdrawals';
  static const String storeWalletBankAccount = '/store/wallet/bank-account';

  // Addresses endpoints
  static const String addresses = '/customer-addresses';
  static String addressDetail(String id) => '$addresses/$id';
  static const String addressesAutocomplete = '/addresses/autocomplete';

  // Notifications endpoints
  static const String notificationsFcmToken = '/notifications/fcm-token';

  // Payments endpoints
  static const String paymentsPayosCreateLink = '/payments/payos/create-link';
  static String paymentsPayosRequest(String id) =>
      '/payments/payos/payment-requests/$id';
  static String paymentsPayosCancel(String id) =>
      '/payments/payos/payment-requests/$id/cancel';
}
