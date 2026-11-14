# Cập nhật UI và hướng dẫn SmartOrder

Ngày: 13/11/2026. Phạm vi: frontend Flutter trong `Mobile`.

## UI đã chỉnh theo ba ảnh tham chiếu

- **Thiết bị:** tiêu đề, mô tả, nút Thêm thiết bị toàn chiều rộng; thẻ ảnh sản phẩm, tên nút, cửa hàng, pin và trạng thái mất kết nối. Nút chưa gán có thao tác Chọn sản phẩm mở component có sẵn.
- **Cửa hàng:** ảnh bìa nếu API có ảnh, tìm kiếm, thẻ sản phẩm hai cột và nút Gán vào nút. Cỡ chữ lớn dùng một cột. Ảnh thiếu/lỗi có hình thay thế.
- **Gán sản phẩm:** chọn nút cùng cửa hàng và số lượng → Kiểm tra thông tin → Xác nhận gán. Chọn nút hoặc Tiếp tục chưa gọi API lưu. Quay lại giữ lựa chọn; lưu lỗi hiển thị cạnh nút xác nhận. Chặn gửi lặp khi đang lưu. Kiểm tra lại cửa hàng của nút trước khi gọi handler cũ.
- **Đơn hàng:** tab đang chọn màu xanh, mã đơn và cửa hàng ở đầu thẻ, tổng tiền và trạng thái thanh toán riêng, nhóm hành động chính/phụ. Tiến trình chuyển vào màn chi tiết; màn chi tiết mở toàn trang.
- **Thanh toán:** tiêu đề đơn hàng/PayOS, số tiền nổi bật, QR, thông tin chuyển khoản và trạng thái chờ. QR, giá và trạng thái vẫn lấy từ luồng API hiện có. Màn thanh toán vẫn sử dụng modal có thể cuộn.

Không sửa API, backend, database, phân quyền hoặc quy tắc đặt hàng/thanh toán. Không đưa tên cửa hàng, QR hay sản phẩm minh họa trong ảnh thành dữ liệu thực của ứng dụng.

## Hướng dẫn tương tác

Dùng lại hệ thống spotlight `SmartOrderTour`, mở rộng thành năm chặng:

1. **Thêm thiết bị:** làm nổi bật nút thật → sheet mã kết nối → nút Kết nối. Chỉ sang thông báo thành công khi luồng hiện có trả kết quả thành công. Back hoặc bỏ thực hành không báo thành công.
2. **Cửa hàng:** làm nổi bật cửa hàng đầu tiên trên Trang chủ; chạm mở danh mục và tự chuyển hướng dẫn đến tiêu đề sản phẩm. Dừng ở giới thiệu, không tự gán sản phẩm.
3. **Đơn hàng:** làm nổi bật hai tab Đang xử lý/Lịch sử; không tự mở thanh toán hay tạo đơn.
4. **Nút và tiền cọc:** giữ chặng có sẵn cho hồ sơ và tài khoản hoàn cọc.
5. **Xác minh danh tính:** giữ chặng có sẵn, chỉ người dùng mới kích hoạt thao tác thật.

Spotlight đo component bằng GlobalKey, cuộn tới mục tiêu, chặn vùng tối, có chỉ dẫn chạm, chỉ báo chặng/bước và Bỏ qua/Tiếp tục. Khi app xuống nền, lớp phủ được gỡ; khi trở lại, chỉ hiển thị với route/mục tiêu hợp lệ. Bộ đo có thời gian chờ giới hạn và nội dung dự phòng khi chưa thấy mục tiêu. Màu chỉ dẫn dùng xanh tương ứng UI mới.

Trạng thái hoàn tất/bỏ qua vẫn lưu theo tài khoản bằng SharedPreferences (`smartorder.spotlight.v1.<account>`). Giữ nguyên khóa để tài khoản đã bỏ qua/hoàn tất trước đây không bị tự hướng dẫn lại.

**Xem lại:** vào **Tài khoản → Xem lại hướng dẫn**. Hướng dẫn sẽ bắt đầu lại từ lời mở đầu.

## File triển khai đã sửa hoặc thêm

Các đường dẫn dưới đây tính từ thư mục `Mobile`:

| Nhóm | File |
| --- | --- |
| Thiết bị | `lib/screens/devices_screen.dart`, `lib/widgets/devices/device_card.dart` |
| Cửa hàng | `lib/screens/store_catalog_screen.dart`, `lib/screens/store_product_assignment.dart` (mới) |
| Kết nối hướng dẫn | `lib/widgets/smart_order_tour.dart`, `lib/screens/main_layout.dart`, `lib/screens/home_screen.dart`, `lib/screens/home/widgets/home_quick_shop_shelf.dart`, `lib/screens/orders_screen.dart` |
| Đơn hàng | `lib/screens/orders/widgets/order_tab_selector.dart`, `lib/screens/orders/widgets/order_card_item.dart`, `lib/screens/orders/widgets/order_detail_bottom_sheet.dart` |
| Thanh toán | `lib/screens/orders/widgets/payos_qr_payment_sheet.dart` |
| Test cập nhật | `test/store_catalog_screen_test.dart`, `test/device_settings_entry_test.dart`, `test/home_and_orders_modular_widgets_test.dart` |
| Test bổ sung | `test/smart_order_tour_flow_test.dart`, `test/assignment_review_test.dart` |

## Kết quả kiểm tra

**42 test đạt** trong tám bộ sau:

```powershell
flutter test --no-pub test/assignment_review_test.dart test/store_catalog_screen_test.dart test/device_settings_entry_test.dart test/home_and_orders_modular_widgets_test.dart test/smart_order_tour_test.dart test/smart_order_tour_flow_test.dart test/payos_prepayment_test.dart test/mobile_paging_timeline_avatar_test.dart
```

Đã kiểm tra bằng widget test: lọc sản phẩm và nút theo cửa hàng, chọn số lượng, không lưu trước xác nhận, quay lại, phản hồi lỗi lưu, mở cài đặt thiết bị, truyền chạm vào target thật, tự chuyển bước sau mở modal, Back không báo thành công, Tiếp tục không kích hoạt handler thật, lưu bỏ qua/hoàn tất theo tài khoản, xem lại, app xuống nền/trở lại và thẻ thiết bị ở 320 px với chữ thường/gấp đôi.

Static analysis của 13 file triển khai không có lỗi biên dịch; còn một cảnh báo đã có trước: `_showAssignProductSheet` không được gọi trong `home_screen.dart`. `git diff --check` cho các file triển khai đã sửa không báo lỗi khoảng trắng.

Trong bộ test FCM có log plugin local notifications chưa khởi tạo trong môi trường widget test; các assertion vẫn đạt. Kết quả này không xác minh khả năng hiển thị push notification trên điện thoại thật.

## Chưa xác minh trên thiết bị thật

Chưa chạy đối chiếu ảnh trực quan trên điện thoại/giả lập trong lần sửa này. Cần thử thêm giao dịch PayOS thực trong môi trường kiểm thử, FCM, bàn phím hệ thống, quyền hệ điều hành và mã của nút SmartOrder thật. Luồng thêm thiết bị đang dùng mã kết nối có sẵn trong source; không thay bằng ghép BLE, cũng không tuyên bố đã xác minh ghép phần cứng thành công. Các bước BLE/Wi-Fi mô phỏng ở onboarding nằm ngoài phạm vi lần sửa này.
