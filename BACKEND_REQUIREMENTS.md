# Những phần backend cần bổ sung cho mobile

Đối chiếu ngày 04/11/2026, commit [`a7da179`](https://github.com/AmazonButton/Backend/tree/a7da179f1d12daaf27b790488b2b4c27fdc7f712). File này tổng hợp các phần còn thiếu; các URL đề xuất bên dưới chưa phải API hiện có.

## Kiểm tra lại ngày 06/11/2026

**Kết luận: chưa đủ cho toàn bộ nghiệp vụ mobile đã chốt.** GitHub `main` và `feature/security-invariant-hardening` vẫn ở `a7da179`; chưa có commit mới trên main so với lần đối chiếu 04/11. Nhánh `feature/platform-button-rental-hardening` chậm hơn main 17 commit. Nhánh `dev` ở `84f262d` ngày 01/11, có lịch sử không chung tổ tiên với main nên không coi là bản đã hợp nhất vào main.

Đã đọc lại trực tiếp trên GitHub: `rental-pricing.ts`, `rentals.service.ts`, `rentals.controller.ts`, `rental-response.dto.ts`, `media.controller.ts`, `devices.service.ts`, `products.controller.ts` tại commit trên. Các mục P1/P2 bên dưới vẫn còn: thu riêng tiền cọc CUSTOMER, API đọc tiến trình trả/hoàn cọc, dữ liệu quyền dùng/phân trang thiết bị và bộ lọc sản phẩm. F09 đã có API timeline/FCM như phần cuối file.

Đây là kiểm tra mã nguồn và hợp đồng API; chưa xác minh bản đang deploy hoặc chạy giao dịch thật. Không sửa source backend trong lần kiểm tra này.

## P1 — Thu tiền cọc khách hàng riêng với phí thuê của store

**Nghiệp vụ đã chốt:** khách hàng chỉ cọc tiền nút; phí thuê/gia hạn thuộc phía store. Hoàn cọc về tài khoản ngân hàng chính chủ sau khi khách trả nút và cửa hàng xác nhận tiếp nhận, theo quy trình duyệt/chi trả của hệ thống. Không cần ví CUSTOMER.

Hiện `src/rentals/rental-pricing.ts` và `createRentalContract()` vẫn tính `monthlyPrice × months + depositFee` trong khoản thu gắn với khách. Cần tách payer và loại khoản thu: CUSTOMER chỉ trả DEPOSIT; STORE trả RENT/duy trì nếu nghiệp vụ yêu cầu. Có thể dùng chung API thanh toán/PayOS hiện có; không bắt buộc thêm endpoint riêng. Khoản thu của khách chỉ gồm tiền cọc, số tiền do server tính, có ownership và idempotency.

Mobile hiện không gọi tạo hợp đồng/gia hạn hoặc thanh toán tổng tiền thuê+cọc, để tránh thu phí thuê từ khách.

## P1 — Lịch sử trả nút và trạng thái chi trả hoàn cọc cho CUSTOMER

Backend đã có gửi yêu cầu trả, cửa hàng xác nhận tiếp nhận, duyệt và chi trả hoàn cọc. Tuy nhiên `GET /rentals/my-rentals` và `GET /rentals/:id` dùng `RentalResponseDto`, chưa trả lịch sử trả/hoàn cọc.

Cần mở rộng DTO hiện có hoặc thêm API đọc được scope theo CUSTOMER, với:

- Yêu cầu trả: `returnId`, `buttonId`, trạng thái, thời gian gửi/tiếp nhận, ghi chú kiểm tra được phép hiển thị.
- Hoàn cọc: `refundId`, số tiền, trạng thái duyệt/chuyển tiền/thành công/thất bại/đối soát, `refundedAt`, ngân hàng/số tài khoản **đã che**, lý do chậm/trả lỗi phù hợp để khách hiểu.
- Số tiền đã cọc, đang giữ, đang chờ hoàn và đã hoàn, tránh suy ra từ trạng thái hợp đồng.

Không trả số tài khoản đầy đủ, dữ liệu mã hóa, token hay secret. Kiểm tra ownership ở service/repository. Gửi yêu cầu trả không được tự đổi sang đã nhận nút hoặc đã hoàn tiền. Với hợp đồng nhiều nút, cần trạng thái cho từng nút và quy tắc hoàn tương ứng.

Mobile hiện chỉ hiển thị sự kiện gửi yêu cầu trong phiên và trạng thái hồ sơ server trả. Chưa thể phục hồi đầy đủ yêu cầu đang chờ sau khi đóng/mở màn hoặc xác nhận đã nhận tiền hoàn cọc khi API chưa trả thông tin đó.

## Phạm vi đã điều chỉnh — Avatar CUSTOMER (F11)

Theo quyết định ngày 06/11/2026, CUSTOMER không cần upload, thay hoặc gỡ ảnh hồ sơ. Bỏ các yêu cầu mở quyền upload, endpoint avatar và gỡ ảnh khỏi phạm vi backend cần bổ sung. Việc CUSTOMER không có quyền gọi API upload không còn được tính là thiếu chức năng.

## Phạm vi đã điều chỉnh — Xóa tài khoản và gỡ liên kết khi trả nút

Xóa tài khoản không thuộc phạm vi yêu cầu theo quyết định ngày 06/11/2026.

F12 (gỡ/chuyển liên kết thủ công) và F14 (cài đặt ứng dụng, xóa tài khoản) đã được bỏ khỏi phạm vi. Mobile bỏ các nút tương ứng; luồng trả nút/hoàn cọc F06 vẫn giữ nguyên. Đổi Wi-Fi thuộc F02 do thành viên khác đảm nhận, không bị xóa cùng F12.

Với nút thuê, `confirmReturnReceiptTx()` đã tự gỡ `customerId`, `rentalId`, `addressId`, chuyển nút về kho store và chặn đặt hàng trong cùng transaction khi xác nhận tiếp nhận thành công. Không cần thêm thao tác gỡ liên kết riêng trên mobile cho luồng trả nút. Nếu kiểm tra cọc/quyền nhận trả thất bại thì transaction rollback. Hồ sơ hoàn cọc được tạo ở trạng thái `PENDING_APPROVAL`; nhận nút không đồng nghĩa đã chuyển tiền hoàn cọc. Chuyển nút trực tiếp giữa hai khách là nghiệp vụ riêng, chưa coi là bắt buộc.

## P2 — Trạng thái và phân trang thiết bị (F08/F10)

`DevicesService.formatButton()` đang bỏ `canOrder`, `inventoryState`, `rentalId` dù database có nghiệp vụ tương ứng. Nên trả trực tiếp các trường này và lý do không được đặt hàng; bổ sung quyền sử dụng hiệu lực theo server, có thể thêm `rentalStatus`/mốc thời gian nếu hữu ích.

`DevicesService.list()` hiện trả toàn bộ mảng, chưa áp dụng `page`, `pageSize` hoặc `search`. Cần phân trang/search trên server, giữ scope CUSTOMER/STORE và thứ tự ổn định. Đề nghị envelope chung:

```json
{"success":true,"data":[],"pagination":{"page":1,"pageSize":20,"totalItems":0,"totalPages":0,"hasNextPage":false}}
```

Mobile đọc được mảng legacy, metadata top-level và dạng `{data:{items,...}}`, lấy các trang khi server có metadata. Khi thiết bị chưa trả quyền dùng, mobile bổ sung từ hồ sơ nút; dữ liệu này chưa thể thay thế trạng thái riêng của nút đang trả trong hợp đồng nhiều nút. Backend tạo đơn vẫn phải kiểm tra quyền dùng thực tế.

## P2 — Bộ lọc sản phẩm và thống nhất pagination (F08)

`ProductQueryDto` nhận `search`/`category`, nhưng controller chỉ chuyển storeId và pagination sang `ProductsService.list()`, nên hai bộ lọc chưa được áp dụng. Cần chuyển/validate/áp dụng chúng ở repository nếu muốn tìm kiếm/phân trang thực sự theo bộ lọc trên server. Catalog mobile hiện lấy đủ các trang của store rồi tìm trong dữ liệu đã tải.

Products trả `pagination.total` trong khi stores/orders dùng envelope mới với `totalItems`/`hasNextPage`. Client đã tương thích cả hai; nên chuẩn hóa dần để các client không phải suy đoán. Không cần thêm API danh sách stores/orders mới: API hiện tại đã có phân trang.

## Đã có, không phải thiếu backend

- `GET /orders` hỗ trợ page/pageSize và lọc status/paymentStatus/fromDate/toDate.
- `GET /orders/:id/timeline` có các sự kiện thật, thời gian và ảnh POD nếu đã có bằng chứng giao hàng.
- FCM tạo đơn/thay đổi trạng thái đã có. Client dùng thông báo để tải lại dữ liệu server; chưa cần thêm Socket.io chỉ để đạt F09.
- Thêm tài khoản ngân hàng CUSTOMER, tạo phiên xác minh 2.000đ, kiểm tra trạng thái và lịch sử đã có. Khoản xác minh/hoàn khoản xác minh khác tiền cọc/hoàn cọc nút.
- F13 đã có `POST /auth/google-login`, `POST /auth/change-password` và API tạo/list/đọc session/decision trong `/identity-verifications/sessions`. Mobile đã nối ba luồng này. Google cần cấu hình OAuth client của ứng dụng; eKYC cần cấu hình Didit phía server. Đây là cấu hình tích hợp, không phải yêu cầu xây thêm API.

Xác minh ngân hàng thực tế cần cấu hình provider hợp lệ. Không coi feature flag tắt hoặc thiếu cấu hình production là bằng chứng API chưa được triển khai. Chưa thực hiện thanh toán, OTP hay upload tài khoản thật trong các đợt kiểm thử mobile; test dùng mock theo contract.
