# Responsive và đồng bộ widget SmartOrder — phần B

Ngày: 14/11/2026. Phạm vi: frontend Flutter; căn cứ tài liệu `SmartOrder_Prompt_Responsive_Dong_Bo_Widget.md` người dùng cung cấp.

## Nguyên nhân có bằng chứng

1. `lib/screens/device_detail_screen.dart`: `Center` bọc `ConstrainedBox` và `SingleChildScrollView`. Khi nội dung thấp hơn viewport, khối cuộn co theo nội dung và bị căn giữa dọc. Không có vùng hero/animation tại vị trí khoảng trắng trong mã hiện tại. Đã đổi sang căn trên, giữ nội dung và callback.
2. `lib/main.dart` và `signup_theme.dart` dùng tên font `Be Vietnam Pro`, nhưng `pubspec.yaml` khai báo family `SampleA Vietnam` cho các file BeVietnamPro. Đã thống nhất tên khai báo, không thêm font/package.
3. Màu primary khác nhau ở AppColors, SampleA, Resident và Login; nhiều widget chép lại literal xanh/viền/chữ. Đã chuyển các literal trùng về token và cho các lớp tương thích dùng cùng nguồn.
4. Sheet chọn sản phẩm dùng header/footer cố định quanh Expanded danh sách; footer cộng bàn phím, làm giảm mạnh chỗ cho danh sách. Đã dùng CustomScrollView với SliverList.builder và header/footer cuộn cùng; giữ số lượng, kiểm tra tồn kho, điều kiện lưu và callback.
5. Hàng thông tin chuyển khoản dùng Row chứa các Text không co giãn; tên/số dài có thể tràn. Đã dùng hàng label/value chung có Expanded, cho đọc toàn bộ giá trị và vùng sao chép tối thiểu 48px.

## Nguồn giao diện chuẩn

- Màu: `lib/constants/app_colors.dart`; primary xanh #2563EB, primaryDark #1D4ED8. `SampleA` và `resident_ui.dart` dùng lại nguồn này.
- Typography, spacing, radius, giới hạn chiều rộng: `SampleA` trong `lib/widgets/sample_a.dart`. Font family `SampleA Vietnam`, title/section/body/caption; spacing 4/8/12/16/24/32; radius card20/button16/sheet24; width form480/detail600/list960 logical px.
- Theme toàn ứng dụng trong `main.dart` dùng typography chuẩn, button minimum 48×48 và helper/error nhiều dòng. SignupTheme dùng lại font/primary.
- Tiếp tục dùng ACard, AButton, AIconButton, AStatus, AProductImage; giữ phản hồi nhấn, haptic và animation hiện có.
- AContent: căn trên, giới hạn chiều rộng; không tạo Scaffold/scroll/controller hay gọi API.
- ASectionHeader: tiêu đề và hành động chuyển hàng khi hẹp/chữ lớn.
- AInfoRow: label/value đầy đủ, tùy chọn sao chép; dùng ở xác nhận gán và PayOS.
- ASheetScroll: một vùng cuộn, keyboard inset, SafeArea, giới hạn chiều rộng; dùng ở kết nối và PayOS.
- ResidentScaffold/ResidentPanel tiếp tục dùng cho nhóm tài khoản, giờ chung token và maxWidth. Không xóa các component cũ còn được tham chiếu.

## Các nhóm màn đã chuyển đổi

| Nhóm | Thay đổi |
|---|---|
| Chi tiết thiết bị | Căn trên, width chuẩn; giữ layout pin/Wi-Fi thích ứng và đường vào cấu hình; giữ tất cả callback |
| Trang chủ | Khung rộng tối đa960; header mục dùng ASectionHeader; token màu/font dùng chung; giữ grid tự cao và ảnh132 |
| Thiết bị | Khung rộng tối đa960, card dùng token; kết nối dùng ASheetScroll |
| Cửa hàng | Khung960, header chung, grid tăng tới4 cột tùy vùng rộng; chữ lớn dùng1 cột |
| Chọn sản phẩm | Một vùng cuộn sliver, danh sách lazy, search/CTA không khóa chiều cao chứa chữ; giữ callback, validation và tồn kho |
| Xác nhận gán | Khung chi tiết600, AInfoRow; không thêm bước mới |
| Đơn hàng/chi tiết | Khung danh sách960/chi tiết600; màu/font chung, giữ tab/timeline/điều kiện hành động |
| PayOS | ASheetScroll cho toàn nội dung; AInfoRow với giá trị đầy đủ và nút sao chép; giữ QR/API/polling |
| Tài khoản/địa chỉ | Khung600, token chung; bỏ chiều cao cứng CTA lưu địa chỉ |
| Nút và tiền cọc/xác minh/ngân hàng | Dùng ResidentScaffold/Panel đã đồng bộ, giữ dữ liệu/trạng thái thực |
| Đăng nhập/đăng ký/Wi-Fi | Font/primary chuẩn; form login max480; giữ animation/scroll/handler; bỏ chiều cao cứng CTA Wi-Fi |

Các hình ảnh, QR và biểu tượng có kích thước theo vai trò; không scale toàn màn hình và không tắt text scaling. Những style cục bộ có vai trò riêng (ví dụ nhãn nhỏ, ảnh bìa, biểu tượng trạng thái) vẫn được giữ; không ép mọi thành phần có cùng hình thức.

## Kiểm tra đã chạy

**327 bài kiểm tra đạt** trong lượt tổng hợp cuối (`responsive-final-tests.log`).

- Màn chi tiết thiết bị: 7 kích thước ×3 text scales, tên dài, giá dài, thiếu Wi-Fi; kiểm tra khối đầu xuất hiện gần AppBar và cuộn tới cấu hình.
- Nhóm tài khoản: 6 biến thể gồm địa chỉ rỗng/có dữ liệu ×7 kích thước ×3 scales.
- Trang chủ/Thiết bị/Đơn hàng/Cửa hàng/Đăng nhập: 5 trang ×7 kích thước ×3 scales; kiểm tra layout trước/sau cuộn.
- Kích thước logical px: 320×568, 360×640, 390×844, 430×932, 600×960, 800×1280, 844×390. Text scales:1.0/1.3/2.0.
- Component chung: action wrap, callback một lần, busy không gọi callback, giữ dữ liệu khi keyboard inset đổi.
- Sheet sản phẩm: màn nhỏ và ngang với keyboard inset200, cuộn tới Lưu; không gửi PUT khi chỉ kiểm tra UI.
- Hồi quy: chọn/gán sản phẩm, lỗi lưu/thử lại, tồn kho, đăng nhập, chi tiết thiết bị, PayOS, địa chỉ, ngân hàng, trả nút và tour. Sửa fixture test đăng nhập để có AddressProvider như app thật; không đổi Provider trong app.
- git diff --check: không có lỗi khoảng trắng.

Không thay đổi backend, service, request payload, auth, quyền hoặc quy tắc nghiệp vụ trong đợt này. Những thay đổi sẵn có ở các file đó trước đợt responsive được giữ nguyên.

## Giới hạn xác minh

ADB thấy emulator-5554 nhưng trạng thái offline. Chưa chạy giao diện trên điện thoại/giả lập hoạt động; chưa có screenshot runtime mới. Widget tests dùng mock, không phải bằng chứng mọi thiết bị hoặc mọi trạng thái đều được hỗ trợ. Chưa kiểm thử toàn bộ tổ hợp bàn phím + font thật + dữ liệu tải từ server; không thực hiện thanh toán, xác minh hoặc trả nút thật.

Các kiểm tra ma trận trang chính dùng dữ liệu mẫu/mock và một số trạng thái rỗng; các kiểm tra hồi quy riêng bao phủ dữ liệu, lỗi và callback. Đây không phải ma trận đầy đủ cho mọi trạng thái API trên mọi kích thước.

## Cách dùng cho màn mới

Dùng `AContent(child: ListView(...))` cho trang chi tiết hoặc `maxWidth: SampleA.listWidth` cho danh sách. Không bọc vùng cuộn ngắn bằng Center nếu muốn nội dung bắt đầu trên cùng. Dùng SampleA typography/màu, ACard/AButton/AStatus và ASectionHeader cho cùng ý nghĩa UI. Dùng AInfoRow cho giá trị quan trọng, ASheetScroll cho sheet ngắn; danh sách dài dùng sliver như ProductSelectionSheet. Component trình bày chỉ nhận dữ liệu/callback, không gọi service. Kiểm tra ít nhất màn hẹp/chữ lớn/bàn phím trước khi thêm override.

## Kết quả phân tích mã

`flutter analyze --no-pub` đã hoàn tất sau120,3 giây: không có error; còn1 warning và2 info đã thấy ở lần kiểm tra đầu:

- `home_screen.dart`: `_showAssignProductSheet` chưa được tham chiếu.
- `services/goong_service.dart`: thiếu ngoặc khối cho if.
- `test/order_product_image_test.dart`: import tương đối vào lib.

Dart analyzer chạy đối chiếu cũng trả cùng3 mục. Chưa sửa các mục ngoài nội dung responsive này; không tuyên bố analyze hoàn toàn sạch.
