import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  /// Default host URL according to runtime platform:
  /// - Android emulator uses 10.0.2.2 to reach host machine's localhost
  /// - iOS Simulator, Desktop (Windows/macOS), and Web use localhost:3000
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api/v1';
      }
    } catch (_) {
      // Fallback for non-standard platforms
    }
    return 'http://localhost:3000/api/v1';
  }

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

  // Devices endpoints
  static const String devices = '/devices';
  static const String devicesLookupCode = '/devices/lookup-code';
  static const String devicesConfigureByCode = '/devices/configure-by-code';
  static const String devicesFleetStats = '/devices/fleet/stats';
  static String deviceDetail(String id) => '/devices/$id';
  static String deviceCustomerConfig(String id) => '/devices/$id/customer-config';
  static String deviceToggleActive(String id) => '/devices/$id/toggle-active';
  static String deviceSimulatePress(String id) => '/devices/$id/simulate-press';
  static String deviceTelemetry(String id) => '/devices/$id/telemetry';
  static String devicePair(String id) => '/devices/$id/pair';
  static String deviceRepair(String id) => '/devices/$id/re-pair';
  static String deviceAssignProduct(String id) => '/devices/$id/assign-product';
  static String deviceRemoveProduct(String id) => '/devices/$id/product';

  // Products endpoints
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';

  // Orders endpoints
  static const String orders = '/orders';
  static const String ordersQuickReorder = '/orders/quick-reorder';
  static const String ordersSimulatePress = '/orders/simulate-button-press';
  static String orderDetail(String id) => '/orders/$id';
  static String orderCancel(String id) => '/orders/$id/cancel';
  static String orderStatus(String id) => '/orders/$id/status';

  // Provisioning endpoints
  static const String provisioningSession = '/provisioning/session';
  static const String provisioningVerify = '/provisioning/verify';
  static String provisioningChangeWifi(String id) => '/provisioning/devices/$id/change-wifi';

  // Media endpoints
  static const String mediaUpload = '/media/upload';
  static const String mediaSignature = '/media/signature';

  // Stores & Rentals & Wallet endpoints
  static const String stores = '/stores';
  static String storeDetail(String id) => '/stores/$id';
  static const String rentalPackages = '/rentals/packages';
  static const String rentalOrder = '/rentals/order';
  static const String myRentals = '/rentals/my-rentals';
  static const String storeWallet = '/store/wallet';
  static const String storeWalletTransactions = '/store/wallet/transactions';
  static const String storeWalletWithdrawals = '/store/wallet/withdrawals';
  static const String storeWalletBankAccount = '/store/wallet/bank-account';
}
