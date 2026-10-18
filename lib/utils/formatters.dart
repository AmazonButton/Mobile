/// Utility module for string formatting across the SmartOrder Mobile app.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Định dạng số tiền sang chuẩn Việt Nam Đồng (VND) với dấu chấm phân cách hàng nghìn
  /// Ví dụ: 65000 -> "65.000đ", 380000 -> "380.000đ"
  static String format(num amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()}đ';
  }

  /// Trích xuất giá trị số từ chuỗi đã định dạng
  /// Ví dụ: "65.000đ" -> 65000
  static num parse(String? formatted) {
    if (formatted == null || formatted.isEmpty) return 0;
    final digits = formatted.replaceAll(RegExp(r'[^\d]'), '');
    return num.tryParse(digits) ?? 0;
  }
}

/// Bộ định dạng thời gian và ngày tháng
class DateTimeFormatter {
  DateTimeFormatter._();

  /// Định dạng thời gian đơn hàng thân thiện (Hiển thị 'Hôm nay' nếu cùng ngày)
  /// Ví dụ: "14:30, Hôm nay" hoặc "09:15, 18/10/2026"
  static String formatOrderTime(DateTime dt, {DateTime? now}) {
    final localDt = dt.toLocal();
    final current = now ?? DateTime.now();

    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');

    if (localDt.day == current.day &&
        localDt.month == current.month &&
        localDt.year == current.year) {
      return '$hour:$minute, Hôm nay';
    } else {
      final day = localDt.day.toString().padLeft(2, '0');
      final month = localDt.month.toString().padLeft(2, '0');
      return '$hour:$minute, $day/$month/${localDt.year}';
    }
  }

  /// Định dạng ngày dạng dd/MM/yyyy
  static String formatDate(DateTime dt) {
    final localDt = dt.toLocal();
    final day = localDt.day.toString().padLeft(2, '0');
    final month = localDt.month.toString().padLeft(2, '0');
    return '$day/$month/${localDt.year}';
  }

  /// Định dạng giờ và ngày dạng HH:mm - dd/MM/yyyy
  static String formatDateTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');
    final day = localDt.day.toString().padLeft(2, '0');
    final month = localDt.month.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month/${localDt.year}';
  }

  /// Chuyển đổi an toàn chuỗi ISO/timestamp sang DateTime
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }
}

/// Bộ định dạng số điện thoại
class PhoneFormatter {
  PhoneFormatter._();

  /// Che số điện thoại bảo mật theo chuẩn OTP (Ví dụ: "0901234567" -> "+84 90xx xxx 567")
  static String formatMasked(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 10) return phone;
    return '+84 ${cleaned.substring(1, 3)}xx xxx ${cleaned.substring(cleaned.length - 3)}';
  }

  /// Định dạng số điện thoại có dấu cách (Ví dụ: "0901234567" -> "090 123 4567")
  static String formatSpaced(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return phone;
  }
}
