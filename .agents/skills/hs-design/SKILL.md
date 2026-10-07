---
name: hs-design
description: Sử dụng khi cần thiết kế giao diện (UI/UX), tạo trang Landing Page, hiệu ứng chuyển động (animations) sử dụng phong cách của Magic UI, Aceternity UI, Lobe UI, hoặc Motion Primitives.
---

# Hướng dẫn Thiết kế UI/UX Premium (Framer Motion & TailwindCSS)

Khi nhận diện tác vụ thiết kế giao diện, lập trình, hoặc tối ưu hóa trải nghiệm người dùng, AI phải tuân thủ các chỉ dẫn kỹ thuật sau đây:

## 1. Triết lý Thiết kế (Aesthetics & Rhythm)
- **Vibrant & Glassmorphism**: Sử dụng viền phát sáng siêu mỏng (`border-[0.5px] border-white/10`), nền làm mờ bằng kính (`backdrop-blur-md bg-black/40`), và đổ bóng nhiều lớp (layered shadows).
- **Rhythm through contrast**: Phân cấp nội dung rõ ràng, kết hợp hài hòa giữa khoảng cách chật (tight groupings) và rộng (generous separations) bằng cách sử dụng `clamp()` hoặc các đơn vị linh hoạt.
- **Bans (Các điều cấm kỵ)**:
  - **KHÔNG** hover phóng to trực tiếp phần tử `<img>` một cách đơn điệu (đây là đặc trưng của AI thế hệ cũ). Thay vào đó, hãy animate viền, bóng, hoặc màu nền của thẻ bọc ngoài.
  - Tránh sử dụng màu xám chữ quá mờ trên nền trắng tint (phải đảm bảo độ tương phản text contrast >= 4.5:1).

## 2. Thư viện UI/UX Tham chiếu & Demo
Khi đề xuất giải pháp, hãy hướng dẫn người dùng hoặc trực tiếp tham chiếu cấu trúc thiết kế từ các kho mã nguồn:
* **Magic UI**: 
  - *Demo & Code*: [magicui.design](https://magicui.design/)
  - *GitHub*: [magicuidesign/magicui](https://github.com/magicuidesign/magicui)
  - *Tác dụng*: Phù hợp cho Landing Page, các thẻ tương tác sáng tạo (Magic Card, Border Beam), hiệu ứng chữ.
* **Aceternity UI**:
  - *Demo & Code*: [ui.aceternity.com](https://ui.aceternity.com/)
  - *GitHub*: [github.com/aceternity](https://github.com/aceternity)
  - *Tác dụng*: Phù hợp cho hiệu ứng nâng cao (3D Pin, Grid Background, Typewriter, Hover Effect).
* **Motion Primitives**:
  - *Demo & Code*: [motion-primitives.com](https://motion-primitives.com/)
  - *GitHub*: [ibelick/motion-primitives](https://github.com/ibelick/motion-primitives)
  - *Tác dụng*: Các vi chuyển động tinh tế (micro-interactions) mang tính trải nghiệm người dùng cao.
* **Lobe UI**:
  - *Demo & Code*: [ui.lobehub.com](https://ui.lobehub.com/)
  - *GitHub*: [lobehub/lobe-ui](https://github.com/lobehub/lobe-ui)
  - *Tác dụng*: Chuẩn thiết kế cho các bảng chat AI, chatbot, bong bóng chat và giao diện nhập liệu thông minh.

## 3. Quy trình Triển khai Code
1. **Copy-paste trước**: AI nên hướng dẫn người dùng tìm component ưng ý trên trang chủ của thư viện, copy mã nguồn `.tsx` lưu vào thư mục dự án (ví dụ: `src/components/ui/`) để đảm bảo không bị thừa file thư viện không cần thiết.
2. **AI Tích hợp**: AI đọc file component mẫu vừa tạo, phân tích các thuộc tính của Framer Motion và TailwindCSS, sau đó tùy chỉnh nội dung (ví dụ: thay đổi giỏ hàng, thông tin cá nhân) mà vẫn giữ nguyên cấu trúc chuyển động gốc của thiết kế.
