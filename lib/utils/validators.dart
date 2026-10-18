/// Utility module for input validation across the SmartOrder Mobile app.
class EmailValidator {
  EmailValidator._();

  static const List<String> popularDomains = [
    'gmail.com',
    'yahoo.com',
    'outlook.com',
    'icloud.com',
    'hotmail.com',
  ];

  static final RegExp strictEmailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+([.-][a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$',
  );

  /// Tính khoảng cách Levenshtein giữa 2 chuỗi
  static int levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  /// Kiểm tra lỗi typo tên miền phổ biến (ví dụ: gmial.com -> gmail.com)
  static String? checkTypo(String text) {
    if (!text.contains('@')) return null;
    final parts = text.split('@');
    if (parts.length != 2) return null;

    final localPart = parts[0].trim();
    final domainPart = parts[1].toLowerCase().trim();

    if (localPart.isEmpty || domainPart.isEmpty) return null;
    if (popularDomains.contains(domainPart)) return null;

    String? bestMatch;
    int lowestDistance = 999;

    for (final popularDomain in popularDomains) {
      final distance = levenshteinDistance(domainPart, popularDomain);
      if (distance <= 2 && distance < lowestDistance) {
        lowestDistance = distance;
        bestMatch = popularDomain;
      }
    }

    if (bestMatch != null) {
      return '$localPart@$bestMatch';
    }
    return null;
  }

  /// Xác thực địa chỉ email. Trả về thông báo lỗi hoặc null nếu hợp lệ.
  static String? validate(String? text, {bool allowUsername = true}) {
    if (text == null || text.trim().isEmpty) {
      return 'Vui lòng nhập địa chỉ Email';
    }

    final raw = text.trim();
    if (raw.contains('@')) {
      if (!strictEmailRegex.hasMatch(raw) ||
          raw.contains('@.') ||
          raw.startsWith('@') ||
          raw.contains('..')) {
        return 'Email không đúng định dạng (VD: example@domain.com)';
      }
      return null;
    } else if (allowUsername) {
      if (raw.length < 3) {
        return 'Tên đăng nhập phải có ít nhất 3 ký tự';
      }
      return null;
    } else {
      return 'Email không đúng định dạng (VD: example@domain.com)';
    }
  }

  /// Kiểm tra nhanh email có hợp lệ không
  static bool isValid(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final raw = text.trim();
    return strictEmailRegex.hasMatch(raw) &&
        !raw.contains('@.') &&
        !raw.startsWith('@') &&
        !raw.contains('..');
  }
}

/// Bộ kiểm tra số điện thoại (chuẩn 10 chữ số di động Việt Nam bắt đầu bằng 0)
class PhoneValidator {
  PhoneValidator._();

  static final RegExp vietnamesePhoneRegex = RegExp(r'^0\d{9}$');

  /// Xác thực số điện thoại. Trả về thông báo lỗi hoặc null nếu hợp lệ.
  static String? validate(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    final cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    if (!vietnamesePhoneRegex.hasMatch(cleaned)) {
      return 'Số điện thoại phải gồm 10 số (bắt đầu bằng 0)';
    }
    return null;
  }

  /// Kiểm tra số điện thoại có hợp lệ không
  static bool isValid(String? phone) {
    if (phone == null) return false;
    final cleaned = phone.trim().replaceAll(RegExp(r'\s+'), '');
    return vietnamesePhoneRegex.hasMatch(cleaned);
  }
}

enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Bộ kiểm tra mật khẩu
class PasswordValidator {
  PasswordValidator._();

  /// Xác thực mật khẩu
  static String? validate(String? password, {int minLength = 6}) {
    if (password == null || password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (password.length < minLength) {
      return 'Mật khẩu phải có ít nhất $minLength ký tự';
    }
    return null;
  }

  /// Đánh giá độ mạnh của mật khẩu
  static PasswordStrength checkStrength(String? password) {
    if (password == null || password.length < 6) {
      return PasswordStrength.weak;
    }

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  static bool isValid(String? password, {int minLength = 6}) {
    return password != null && password.length >= minLength;
  }
}
