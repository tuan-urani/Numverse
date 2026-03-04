# Numverse Product Summary

## 1. Định vị sản phẩm

`Numverse` là ứng dụng mobile thần số học thuần cho thị trường Việt Nam, giúp người dùng khám phá bản thân và người xung quanh dựa trên `họ tên + ngày sinh`.

Mục tiêu sản phẩm:
- Giúp người dùng hiểu bản thân và định hướng cuộc sống qua thần số học.
- Tạo trải nghiệm dễ dùng, đáng tin, có cá nhân hóa rõ ràng.
- Tạo lý do quay lại hằng ngày nhờ nội dung theo thời gian.
- Hỗ trợ dùng cho bản thân lẫn người thân.

Định hướng truyền thông:
- Định vị là công cụ `self-discovery / reflection`.
- Không truyền thông như hệ thống dự đoán chắc chắn hay khẳng định tuyệt đối.

## 2. Cấu trúc giá trị cốt lõi

Numverse chia giá trị sản phẩm thành 2 lớp:

### 2.1. Life-based
Các kết quả có giá trị lâu dài, gần như không đổi theo thời gian.

Bao gồm:
- `Chỉ số cốt lõi`
- `Biểu đồ và ma trận`
- `Lộ trình cuộc đời`
- `Chân dung cá nhân`

### 2.2. Time-based
Các kết quả thay đổi theo thời gian để tạo retention.

Bao gồm:
- `Chu kỳ năm`
- `Chu kỳ tháng`
- `Chu kỳ ngày`
- `Insight hằng ngày`
- `Diễn giải theo thời điểm`

## 3. Kiến trúc tab bar

Tab bar hiện tại được chốt gồm 5 tab:

1. `Hôm nay`
2. `Luận giải`
3. `Tương hợp`
4. `NumAI`
5. `Tôi`

## 4. Nội dung từng tab

## 4.1. Tab `Hôm nay`
Đây là tab dành cho toàn bộ `time-based` và phần `Chu kỳ thời gian`.

Bao gồm:
- `Chu kỳ năm`
  - Năm cá nhân
  - Chủ đề / năng lượng năm hiện tại
  - Bài học cần ưu tiên trong năm
- `Chu kỳ tháng`
  - Tháng cá nhân
  - Trọng tâm tháng này
- `Chu kỳ ngày`
  - Ngày cá nhân
  - Mức năng lượng / nhịp ngày
- `Insight hằng ngày`
  - Insight hôm nay
  - Gợi ý hành động hôm nay
  - Điều nên tránh hôm nay
- `Diễn giải theo thời điểm`
  - Đỉnh cao hiện tại đang active
  - Thử thách hiện tại đang active

Ý nghĩa của tab:
- Trả lời câu hỏi: `Hôm nay / tháng này / năm nay mình nên chú ý điều gì?`

## 4.2. Tab `Luận giải`
Đây là tab dành cho toàn bộ `life-based`.

Menu cấp 1 trong tab `Luận giải`:
1. `Chỉ số cốt lõi`
2. `Biểu đồ và ma trận`
3. `Lộ trình cuộc đời`
4. `Chân dung cá nhân`

### a. `Chỉ số cốt lõi`
Bao gồm:
- Số chủ đạo
- Số biểu đạt / vận mệnh
- Số linh hồn
- Số nhân cách

### b. `Biểu đồ và ma trận`
Bao gồm:
- Biểu đồ ngày sinh
- Các số mạnh, yếu, thiếu
- `Matrix Aspect Detail`

Trong `Matrix Aspect Detail` gồm:
- Trục Thể chất
- Trục Cảm xúc
- Trục Trí tuệ
- Các mũi tên nổi bật như quyết tâm, nhạy cảm, và các mẫu hình nổi bật khác trong ma trận

### c. `Lộ trình cuộc đời`
Bao gồm:
- Tổng quan 4 đỉnh cao cuộc đời
- Tổng quan 4 thử thách cuộc đời

### d. `Chân dung cá nhân`
Đây là phần diễn giải tổng hợp bằng ngôn ngữ đời sống, trả lời câu hỏi:
`Con người này ngoài đời vận hành như thế nào?`

Bao gồm:
- Tổng quan tính cách
- Điểm mạnh nổi bật
- Điểm cần cân bằng
- Phong cách giao tiếp
- Phong cách tình cảm / cách yêu
- Định hướng công việc / môi trường phù hợp

## 4.3. Tab `Tương hợp`
Chức năng:
- Đánh giá sự tương hợp với người khác
- Phân tích mối quan hệ cơ bản

Ý nghĩa của tab:
- Trả lời câu hỏi: `Mình hợp với người này ở đâu, dễ xung đột ở đâu?`

## 4.4. Tab `NumAI`
Đây là tab chatbot riêng, độc lập.

Vai trò:
- Giải thích thêm các kết quả trong app.
- Trả lời câu hỏi xoay quanh bộ số, hồ sơ và thông tin của người dùng.
- Tổng hợp insight từ nhiều phần: `Luận giải`, `Hôm nay`, `Tương hợp`.

Nguyên tắc hiện tại:
- `NumAI` là một tab riêng.
- Chưa triển khai CTA từ các tab khác sang chat ở giai đoạn hiện tại.
- `NumAI` được mở cho cả `Free User` và `PRO User`.
- Nếu là `Free User`, mỗi lượt chat sẽ cần tiêu hao một lượng `Soul Point` nhất định.
- Nếu là `PRO User`, có thể chat thuận tiện hơn mà không phải mở lẻ từng lượt bằng `Soul Point`.

## 4.5. Tab `Tôi`
Đây là tab tài khoản / cá nhân thay cho `Settings`.

Có thể bao gồm trong tương lai:
- Hồ sơ của tôi
- Danh sách hồ sơ đã lưu
- Gói dịch vụ
- Cài đặt
- Thông báo
- Quyền riêng tư
- Trợ giúp

## 5. Định nghĩa các lớp nội dung

### 5.1. `Luận giải`
Trả lời câu hỏi:
- `Tôi là ai?`

### 5.2. `Hôm nay`
Trả lời câu hỏi:
- `Hiện tại tôi đang ở đâu và nên chú ý điều gì?`

### 5.3. `Tương hợp`
Trả lời câu hỏi:
- `Tôi và người khác kết nối với nhau như thế nào?`

### 5.4. `NumAI`
Trả lời câu hỏi:
- `Tôi muốn hỏi sâu hơn về hồ sơ, thời điểm hiện tại và mối quan hệ của mình.`

## 6. Mô hình trải nghiệm miễn phí và trả phí

## 6.1. Nguyên tắc chung
- Không quá khắt khe với người dùng ở lần đầu trải nghiệm.
- Người dùng cần được thử một vòng ứng dụng để có cái nhìn overview về giá trị.
- `Luận giải` được mở miễn phí toàn bộ vì đây là phần `life-time`.
- `Hôm nay` là nơi phù hợp nhất để tạo subscription vì đây là giá trị lặp lại.
- `NumAI` được mở cho mọi người dùng, nhưng cách sử dụng sẽ khác nhau giữa `Free` và `PRO`.

## 6.2. Tab `Luận giải`
Định hướng:
- `Free` toàn bộ cho trải nghiệm hồ sơ cá nhân.

## 6.3. Tab `Hôm nay`
Mô hình chốt:
- `Free nhẹ`
- `PRO mở full`
- `Soul Point` dùng để mở xem sâu lẻ

### a. Free nhẹ
Người dùng free được xem:
- `Insight hôm nay` bản ngắn
- `Mức năng lượng / nhịp ngày`
- `1 gợi ý hành động chính`
- Preview ngắn cho `tháng này`, `năm này`, `giai đoạn hiện tại`

### b. PRO mở full
Người dùng PRO được xem đầy đủ:
- Full `Chu kỳ năm`
- Full `Chu kỳ tháng`
- Full `Chu kỳ ngày`
- Full `Insight hôm nay`
- `Nên làm / nên tránh`
- `Đỉnh cao hiện tại đang active`
- `Thử thách hiện tại đang active`

### c. Soul Point xem sâu lẻ
Người dùng free có thể dùng `Soul Point` để mở lẻ:
- `Mở sâu hôm nay`
- `Mở sâu tháng này`
- `Mở sâu năm này`
- `Mở sâu giai đoạn hiện tại`

Nguyên tắc:
- `Soul Point` không mở khóa vĩnh viễn.
- `Soul Point` chỉ là cơ chế trải nghiệm lẻ, không thay thế `PRO`.

## 6.4. Tab `NumAI`
Định hướng monetization:
- Mở cho cả `Free` và `PRO`
- `Free User` dùng `Soul Point` để gửi từng lượt chat
- `PRO User` có trải nghiệm chat thuận tiện hơn và không cần mở lẻ từng lượt bằng `Soul Point`
- Vẫn là một trong các giá trị chính để người dùng nâng cấp lên `VIP PRO`

## 7. Soul Point

`Soul Point` là cơ chế tích điểm để người dùng free có thể thử một số chức năng premium theo từng lượt.

Nguồn tích lũy dự kiến:
- Điểm danh hằng ngày
- Streak hằng ngày
- Xem quảng cáo

Mục tiêu:
- Giảm cảm giác bị paywall quá sớm
- Cho phép user thử premium theo từng lượt
- Tăng retention cho nhóm chưa billing
- Cho phép `Free User` dùng `NumAI` theo cơ chế từng lượt chat

Nguyên tắc thiết kế:
- Không để `Soul Point` trở thành đường thay thế hoàn toàn cho `VIP PRO`
- Dùng để mở các trải nghiệm tiêu hao / dùng lẻ
- `PRO` luôn là lựa chọn tiện hơn cho người dùng thường xuyên
- Với `NumAI`, `Soul Point` nên tiêu hao theo từng lượt chat hoặc từng gói lượt nhỏ

## 8. Hướng monetization tổng thể

Mô hình hiện tại:
- `Luận giải`: miễn phí
- `Hôm nay`: free nhẹ, `PRO` mở full, `Soul Point` xem sâu lẻ
- `NumAI`: mở cho mọi user, `Free` dùng `Soul Point` theo lượt chat, `PRO` dùng thuận tiện hơn
- `Tương hợp`: premium hoặc có thể mở rộng chiến lược sau

Logic kinh doanh:
- `Luận giải` là `hook` để tạo niềm tin và aha moment
- `Hôm nay` là `retention engine`
- `NumAI` là `premium interactive layer`
- `Soul Point` là `bridge` giữa free và trả phí

## 9. Kết luận sản phẩm ở giai đoạn hiện tại

Numverse hiện được định hình như sau:
- Một ứng dụng thần số học thuần cho người Việt
- Có 2 lớp giá trị rõ ràng: `life-based` và `time-based`
- Có 5 tab chính: `Hôm nay`, `Luận giải`, `Tương hợp`, `NumAI`, `Tôi`
- `Luận giải` là vùng đọc hồ sơ nền tảng, miễn phí
- `Hôm nay` là vùng nội dung quay lại hằng ngày, dùng mô hình `free nhẹ + PRO + Soul Point`
- `NumAI` là tab chatbot mở cho mọi user, trong đó `Free User` chat bằng `Soul Point`
- `Tôi` là tab quản lý tài khoản và cá nhân
