# F13 — Google, đổi mật khẩu và xác minh danh tính

Triển khai ngày 06/11/2026. API đối chiếu từ Backend commit `a7da179f1d12daaf27b790488b2b4c27fdc7f712`.

## Đăng nhập Google

Màn đăng nhập có “Tiếp tục với Google”. SDK `google_sign_in` lấy Google ID token thật; mobile gửi duy nhất `{token}` đến `POST /auth/google-login`. Chỉ mở phiên app sau khi backend trả access token và refresh token hợp lệ. Không dùng email do client tự gửi để đăng nhập. Người dùng hủy chọn tài khoản thì ở lại màn đăng nhập, không gọi backend.

Project hiện có Android và Windows, chưa có target iOS. Google native được triển khai cho nền tảng SDK hỗ trợ; Windows/web báo chưa hỗ trợ thay vì đăng nhập giả. Có thể dùng email/OTP như trước.

Android hiện chưa có OAuth client trong `android/app/google-services.json`. Để chạy Google thật:

1. Đăng ký Android OAuth client đúng applicationId hiện tại và SHA chứng thư ký cho từng bản debug/release trong Google Cloud/Firebase.
2. Cấu hình Web OAuth client. Có thể tải lại `google-services.json` có entry `oauth_client` với `client_type: 3`, hoặc truyền Web client ID qua build:

```powershell
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=WEB_OAUTH_CLIENT_ID
```

3. Cấu hình backend `GOOGLE_CLIENT_ID` khớp Web client ID đó để kiểm tra audience. Không nhúng client secret hoặc service-account key vào app.

`GOOGLE_CLIENT_ID` dart-define trên mobile dành cho native client ID khi bổ sung target iOS/macOS, khác `GOOGLE_SERVER_CLIENT_ID`. Target iOS còn cần cấu hình URL scheme theo SDK, chưa được tạo tự động trong đợt này.

Tài liệu chính thức: [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in), [Android OAuth configuration](https://pub.dev/packages/google_sign_in_android).

## Đổi mật khẩu

Tài khoản → Đổi mật khẩu. Nhập mật khẩu hiện tại, mật khẩu mới và nhập lại. Mật khẩu mới tuân thủ DTO backend: ít nhất 8 ký tự, có hoa/thường/số/ký tự đặc biệt, khác mật khẩu cũ. Gửi `POST /auth/change-password` với `currentPassword/newPassword`.

Sai mật khẩu hoặc lỗi server giữ nguyên màn để sửa/thử lại; không báo thành công và không xóa phiên chỉ vì mật khẩu hiện tại sai. Khi backend xác nhận thành công, xóa token local và quay về đăng nhập vì backend đã thu hồi các phiên. Không lưu mật khẩu vào preferences hoặc log. Tài khoản chưa có mật khẩu tiếp tục dùng Google/OTP; khôi phục mật khẩu qua email chỉ phù hợp khi tài khoản có email.

## eKYC Didit

Tài khoản → Xác minh danh tính. Tải lịch sử có phân trang, phục hồi phiên đang chờ; chỉ tạo phiên sau khi người dùng chọn bắt đầu và xác nhận chuyển sang Didit. Không tự tạo phiên lúc mở màn hoặc khi tải lịch sử thất bại.

- Tạo phiên: `POST /identity-verifications/sessions`.
- Danh sách và trạng thái: `GET /identity-verifications/sessions`, `GET /identity-verifications/sessions/:id`.
- Kiểm tra chủ động: `GET /identity-verifications/sessions/:id/decision`, sau đó đọc lại session vì endpoint decision hiện có thể trả status trước khi đồng bộ DB.
- Chỉ mở URL HTTPS thuộc `didit.me` hoặc subdomain; không dùng kết quả đóng trình duyệt/callback làm bằng chứng xác minh thành công.
- Tự đọc lại khi resume; polling mỗi 10 giây, tối đa 5 phút mỗi đợt; dừng khi chạy nền/rời màn/terminal/hết hạn. Có nút kiểm tra thủ công sau đó. Phiên đang xét duyệt không mở lại bước nhập giấy tờ; phiên hết hạn/từ chối có thể tạo lại.
- Không cache ảnh giấy tờ, metadata OCR hoặc decision chứa dữ liệu giấy tờ xuống local. Model chỉ giữ ID, trạng thái, URL, thời gian.

Backend cần cấu hình Didit hợp lệ và webhook đang hoạt động. Callback hiện do backend quyết định; app đọc lại trạng thái khi người dùng quay về. Mobile không giữ API key Didit.

## Phạm vi đã bỏ

Không còn nút xóa/gỡ thiết bị thủ công F12, cài đặt ứng dụng/xóa tài khoản F14, chọn/chụp avatar CUSTOMER. Vẫn hiển thị avatar đã có từ server (ví dụ ảnh Google), và giữ nghiệp vụ trả nút/hoàn cọc F06. Không sửa provisioning BLE/Wi-Fi F02.

## Kiểm chứng

Nhóm mới `test/mobile_f13_test.dart` có 18 test đạt: token exchange, hủy/lỗi/đăng nhập trùng, đổi mật khẩu/thất bại/xóa phiên, eKYC consent/khôi phục/lịch sử/resume/URL và các mục đã bỏ khỏi Profile. Test dùng HTTP mock và URL launcher giả; chưa đăng nhập Google thật hoặc gửi giấy tờ thật tới Didit.

Toàn bộ test: **253 đạt, 12 lỗi baseline**, không có tên test lỗi mới so với đợt F08/F09/F11. Log: `D:\Doan\audit\mobile-f13-all.log`. Test xóa thiết bị cũ đã được cập nhật theo yêu cầu bỏ thao tác gỡ liên kết thủ công.

Analyzer: **0 error, 1 warning, 18 info** (19 issue baseline). Log: `D:\Doan\audit\mobile-f13-analyze-final.log`.

Build Android debug thành công: `build/app/outputs/flutter-apk/app-debug.apk`. Log: `D:\Doan\audit\mobile-f13-build-android.log`. Build chưa truyền Web OAuth client ID; cần cấu hình ID trước khi kiểm tra đăng nhập Google thật. Gradle có cảnh báo công cụ build/SDK cũ nhưng không chặn build; không nâng cấp toolchain ngoài phạm vi F13.
