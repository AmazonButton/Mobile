import 'package:flutter_test/flutter_test.dart';
import 'package:smart_order_button/utils/utils.dart';

void main() {
  group('EmailValidator Tests', () {
    test('levenshteinDistance computes accurate edit distance', () {
      expect(EmailValidator.levenshteinDistance('', ''), equals(0));
      expect(EmailValidator.levenshteinDistance('a', ''), equals(1));
      expect(EmailValidator.levenshteinDistance('', 'abc'), equals(3));
      expect(EmailValidator.levenshteinDistance('gmail.com', 'gmail.com'), equals(0));
      expect(EmailValidator.levenshteinDistance('gmial.com', 'gmail.com'), equals(2));
      expect(EmailValidator.levenshteinDistance('gmai.com', 'gmail.com'), equals(1));
    });

    test('checkTypo suggests correct popular domain typos', () {
      expect(EmailValidator.checkTypo('test@gmial.com'), equals('test@gmail.com'));
      expect(EmailValidator.checkTypo('user@yaho.com'), equals('user@yahoo.com'));
      expect(EmailValidator.checkTypo('admin@outlok.com'), equals('admin@outlook.com'));
      expect(EmailValidator.checkTypo('user@hotmail.com'), isNull); // Correct domain already
      expect(EmailValidator.checkTypo('not_an_email'), isNull);
      expect(EmailValidator.checkTypo('user@completelydifferentunknowncustomdomain.org'), isNull);
    });

    test('validate handles empty, invalid, and username cases', () {
      expect(EmailValidator.validate(null), equals('Vui lòng nhập địa chỉ Email'));
      expect(EmailValidator.validate(''), equals('Vui lòng nhập địa chỉ Email'));
      expect(EmailValidator.validate('   '), equals('Vui lòng nhập địa chỉ Email'));

      // With username allowed
      expect(EmailValidator.validate('ab', allowUsername: true), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      expect(EmailValidator.validate('abc', allowUsername: true), isNull);
      expect(EmailValidator.validate('user123', allowUsername: true), isNull);

      // Without username allowed
      expect(EmailValidator.validate('user123', allowUsername: false),
          equals('Email không đúng định dạng (VD: example@domain.com)'));

      // Email formats
      expect(EmailValidator.validate('test@example.com'), isNull);
      expect(EmailValidator.validate('user.name+tag@sub.domain.vn'), isNull);
      expect(EmailValidator.validate('bad@.com'), equals('Email không đúng định dạng (VD: example@domain.com)'));
      expect(EmailValidator.validate('@domain.com'), equals('Email không đúng định dạng (VD: example@domain.com)'));
      expect(EmailValidator.validate('user@domain..com'), equals('Email không đúng định dạng (VD: example@domain.com)'));
    });

    test('isValid returns boolean strictly for valid email', () {
      expect(EmailValidator.isValid(null), isFalse);
      expect(EmailValidator.isValid(''), isFalse);
      expect(EmailValidator.isValid('abc'), isFalse);
      expect(EmailValidator.isValid('test@example.com'), isTrue);
      expect(EmailValidator.isValid('invalid@com'), isFalse);
    });
  });

  group('PhoneValidator Tests', () {
    test('validate enforces 10-digit Vietnamese mobile number starting with 0', () {
      expect(PhoneValidator.validate(null), equals('Vui lòng nhập số điện thoại'));
      expect(PhoneValidator.validate(''), equals('Vui lòng nhập số điện thoại'));
      expect(PhoneValidator.validate('12345'), equals('Số điện thoại phải gồm 10 số (bắt đầu bằng 0)'));
      expect(PhoneValidator.validate('1900156000'), equals('Số điện thoại phải gồm 10 số (bắt đầu bằng 0)'));
      expect(PhoneValidator.validate('09123456789'), equals('Số điện thoại phải gồm 10 số (bắt đầu bằng 0)')); // 11 digits

      expect(PhoneValidator.validate('0912345678'), isNull);
      expect(PhoneValidator.validate(' 0912 345 678 '), isNull); // trims and cleans spaces
    });

    test('isValid accurately verifies Vietnamese mobile number', () {
      expect(PhoneValidator.isValid(null), isFalse);
      expect(PhoneValidator.isValid(''), isFalse);
      expect(PhoneValidator.isValid('0912345678'), isTrue);
      expect(PhoneValidator.isValid('090 123 4567'), isTrue);
      expect(PhoneValidator.isValid('0812345678'), isTrue);
      expect(PhoneValidator.isValid('0312345678'), isTrue);
      expect(PhoneValidator.isValid('0712345678'), isTrue);
      expect(PhoneValidator.isValid('0512345678'), isTrue);
      expect(PhoneValidator.isValid('1234567890'), isFalse);
    });
  });

  group('PasswordValidator Tests', () {
    test('validate checks minimum required length', () {
      expect(PasswordValidator.validate(null), equals('Vui lòng nhập mật khẩu'));
      expect(PasswordValidator.validate(''), equals('Vui lòng nhập mật khẩu'));
      expect(PasswordValidator.validate('12345', minLength: 6), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(PasswordValidator.validate('123456', minLength: 6), isNull);
      expect(PasswordValidator.validate('password123', minLength: 8), isNull);
    });

    test('checkStrength calculates password strength levels', () {
      expect(PasswordValidator.checkStrength(null), equals(PasswordStrength.weak));
      expect(PasswordValidator.checkStrength('123'), equals(PasswordStrength.weak));
      expect(PasswordValidator.checkStrength('123456'), equals(PasswordStrength.weak));
      expect(PasswordValidator.checkStrength('Pass123'), equals(PasswordStrength.medium));
      expect(PasswordValidator.checkStrength('P@ssw0rd2026!'), equals(PasswordStrength.strong));
    });

    test('isValid checks password validity', () {
      expect(PasswordValidator.isValid(null), isFalse);
      expect(PasswordValidator.isValid('12345'), isFalse);
      expect(PasswordValidator.isValid('123456'), isTrue);
    });
  });

  group('CurrencyFormatter Tests', () {
    test('format transforms numbers into VND currency format', () {
      expect(CurrencyFormatter.format(0), equals('0đ'));
      expect(CurrencyFormatter.format(500), equals('500đ'));
      expect(CurrencyFormatter.format(65000), equals('65.000đ'));
      expect(CurrencyFormatter.format(380000), equals('380.000đ'));
      expect(CurrencyFormatter.format(12500000), equals('12.500.000đ'));
    });

    test('parse extracts numeric value from formatted strings', () {
      expect(CurrencyFormatter.parse(null), equals(0));
      expect(CurrencyFormatter.parse(''), equals(0));
      expect(CurrencyFormatter.parse('65.000đ'), equals(65000));
      expect(CurrencyFormatter.parse('380.000đ'), equals(380000));
      expect(CurrencyFormatter.parse('12.500.000đ'), equals(12500000));
    });
  });

  group('DateTimeFormatter Tests', () {
    final fixedNow = DateTime(2026, 10, 18, 17, 0, 0);

    test('formatOrderTime displays Hôm nay when date is today', () {
      final todayTime = DateTime(2026, 10, 18, 14, 30);
      final formatted = DateTimeFormatter.formatOrderTime(todayTime, now: fixedNow);
      expect(formatted, equals('14:30, Hôm nay'));
    });

    test('formatOrderTime displays full date when date is not today', () {
      final pastTime = DateTime(2026, 10, 15, 9, 5);
      final formatted = DateTimeFormatter.formatOrderTime(pastTime, now: fixedNow);
      expect(formatted, equals('09:05, 15/10/2026'));
    });

    test('formatDate and formatDateTime format standard layouts', () {
      final dt = DateTime(2026, 5, 4, 8, 30);
      expect(DateTimeFormatter.formatDate(dt), equals('04/05/2026'));
      expect(DateTimeFormatter.formatDateTime(dt), equals('08:30 - 04/05/2026'));
    });

    test('tryParse handles various types safely', () {
      expect(DateTimeFormatter.tryParse(null), isNull);
      expect(DateTimeFormatter.tryParse('invalid-date'), isNull);
      expect(DateTimeFormatter.tryParse(DateTime(2026, 1, 1)), equals(DateTime(2026, 1, 1)));
      expect(DateTimeFormatter.tryParse('2026-10-18T10:00:00Z'), isNotNull);
    });
  });

  group('PhoneFormatter Tests', () {
    test('formatMasked applies security masking for OTP flows', () {
      expect(PhoneFormatter.formatMasked('0901234567'), equals('+84 90xx xxx 567'));
      expect(PhoneFormatter.formatMasked(' 0912 345 678 '), equals('+84 91xx xxx 678'));
      expect(PhoneFormatter.formatMasked('12345'), equals('12345')); // too short
    });

    test('formatSpaced formats 10-digit phone numbers with readability spaces', () {
      expect(PhoneFormatter.formatSpaced('0901234567'), equals('090 123 4567'));
      expect(PhoneFormatter.formatSpaced(' 0912345678 '), equals('091 234 5678'));
      expect(PhoneFormatter.formatSpaced('123'), equals('123'));
    });
  });
}
