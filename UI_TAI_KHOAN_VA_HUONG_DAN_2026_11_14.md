# Cập nhật UI tài khoản và hướng dẫn tương tác

Ngày: 14/11/2026. Phạm vi: ứng dụng Flutter trong Mobile.

## Các màn hình đã cập nhật

- **Tài khoản:** hồ sơ gọn với ảnh đại diện, tên, số điện thoại và Chỉnh sửa hồ sơ; chia mục Thông tin cá nhân, Nút & hoàn cọc, Hỗ trợ & bảo mật. Giữ thanh điều hướng hiện có.
- **Địa chỉ giao hàng:** thẻ địa chỉ có lựa chọn, nhãn mặc định, người nhận, số điện thoại và nút sửa. Giữ thao tác đặt mặc định, xóa và thêm địa chỉ. Nội dung rỗng cuộn được khi tăng cỡ chữ; nút thêm nằm trong vùng an toàn phía dưới.
- **Nút và tiền cọc:** thẻ hồ sơ có trạng thái, danh sách nút, yêu cầu trả nút và tiền cọc. Hiển thị tiền cọc theo hồ sơ vì API chưa cung cấp số tiền riêng cho từng nút; không nhân bản số tiền hoặc đưa cửa hàng minh họa vào dữ liệu thật.
- **Xác minh danh tính:** biểu tượng khiên, trạng thái thực, danh sách chuẩn bị, thông báo chuyển sang Didit. Giữ luồng bắt đầu, tiếp tục, kiểm tra trạng thái và lịch sử hiện có.
- **Tài khoản hoàn cọc:** tài khoản được che số, trạng thái thực, khối xác minh màu xanh nhạt, số tiền xác minh 2.000đ theo luồng hiện có, lịch sử và thêm tài khoản.

## Hướng dẫn tương tác

Dựa trên Prompt_Huong_Dan_Tuong_Tac_SmartOrder.md, mở rộng hệ thống spotlight hiện có thành bảy chặng:

1. Thêm thiết bị.
2. Cửa hàng và sản phẩm.
3. Đơn hàng.
4. Địa chỉ giao hàng.
5. Nút và tiền cọc.
6. Tài khoản hoàn cọc.
7. Xác minh danh tính.

Các mục tiêu là widget thật. Mở và đóng màn con cập nhật bước hướng dẫn; Tiếp tục hoặc Bỏ qua không lưu địa chỉ, gửi yêu cầu trả nút, tạo thanh toán hay bắt đầu xác minh. Giữ trạng thái hoàn tất theo tài khoản và xử lý vòng đời ứng dụng của hệ thống hiện có.

Xem lại tại **Tài khoản → Xem lại hướng dẫn**. Giữ khóa lưu trạng thái cũ để người đã hoàn tất không bị tự chạy lại.

## File chính

- lib/screens/profile_screen.dart
- lib/screens/address/address_list_screen.dart
- lib/screens/customer_buttons_screen.dart
- lib/screens/identity_verification_screen.dart
- lib/screens/customer_bank_accounts_screen.dart
- lib/widgets/smart_order_tour.dart

## Kiểm tra

- 53 bài kiểm tra nghiệp vụ và hướng dẫn đã đạt trong đợt kiểm tra hồi quy.
- Sau sửa lỗi tràn, chạy lại 21 bài kiểm tra địa chỉ và responsive: tất cả đạt, gồm 12 trường hợp giao diện ở chiều rộng 320px với cỡ chữ 1x/2x.
- git diff --check không phát hiện lỗi khoảng trắng.
- Chưa kiểm tra trực quan trên điện thoại thật; chưa thực hiện giao dịch thanh toán hoặc xác minh thực tế.

Không thay đổi backend hay hợp đồng API trong đợt cập nhật này.
