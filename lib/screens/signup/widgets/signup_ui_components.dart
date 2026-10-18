import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'signup_theme.dart';

/// Reusable primary CTA button for onboarding steps.
class SignupPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isEnabled;

  const SignupPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: SignupTheme.figmaBlue,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: SignupTheme.fontFamily,
          ),
        ),
      ),
    );
  }
}

/// Reusable secondary text button for onboarding steps.
class SignupSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const SignupSecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: SignupTheme.figmaBlue,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: SignupTheme.fontFamily,
          ),
        ),
      ),
    );
  }
}

/// Circular fallback icon placeholder when an asset image fails to load.
class SignupFallbackIllustration extends StatelessWidget {
  final IconData icon;

  const SignupFallbackIllustration({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: SignupTheme.figmaBlueLight,
        shape: BoxShape.circle,
        border: Border.all(color: SignupTheme.figmaBlueBorder, width: 2),
      ),
      child: Center(
        child: Icon(icon, color: SignupTheme.figmaBlue, size: 56),
      ),
    );
  }
}

/// Modal bottom sheet presenting onboarding help & troubleshooting guide.
void showSignupHelpBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SignupTheme.figmaBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SignupTheme.figmaBlueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.helpCircle, color: SignupTheme.figmaBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Cần hỗ trợ cài đặt?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: SignupTheme.figmaDark,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                '1. Kích hoạt nút bấm',
                'Nhấn giữ nút tròn khoảng 6 giây cho đến khi đèn LED nhấp nháy xanh dương liên tục.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                '2. Mạng Wi-Fi tương thích',
                'Nút bấm IoT chỉ hỗ trợ băng tần 2.4GHz. Vui lòng không chọn mạng 5GHz.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                '3. Quyền Bluetooth',
                'Đảm bảo Bluetooth trên điện thoại đã bật và cấp quyền tìm kiếm thiết bị gần đây.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SignupTheme.figmaBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      fontFamily: SignupTheme.fontFamily,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildHelpItem(String title, String desc) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: SignupTheme.figmaDark,
          fontFamily: SignupTheme.fontFamily,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        desc,
        style: const TextStyle(
          fontSize: 13,
          color: SignupTheme.figmaMuted,
          height: 1.4,
          fontFamily: SignupTheme.fontFamily,
        ),
      ),
    ],
  );
}
