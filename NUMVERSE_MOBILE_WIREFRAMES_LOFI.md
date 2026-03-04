# Numverse Mobile Wireframes Low-Fi

## Mục đích tài liệu

Tài liệu này tổng hợp toàn bộ `mobile wireframe low-fi` cho các tab và các màn đã được define tới thời điểm hiện tại.

Phạm vi:
- Chỉ tập trung vào `information architecture`, `cấu trúc màn hình`, `thứ tự nội dung`, `entry point`, và `trạng thái truy cập`.
- Chưa đi vào UI visual design, màu sắc, typography, motion.

## Ký hiệu dùng trong tài liệu

- `Mã màn`: ID để review nhanh.
- `Access`: Quyền truy cập chính của màn.
- `Primary goal`: Mục tiêu chính của màn.
- `Note`: Chú thích để hiểu ý đồ UX.

Các mức truy cập:
- `Free`: người dùng miễn phí xem được đầy đủ màn đó.
- `Free preview`: người dùng miễn phí xem được một phần.
- `PRO`: chỉ dành cho người dùng PRO.
- `Soul Point`: có thể mở lẻ bằng Soul Point.

## 1. App Shell

### Screen `APP-01` - Tab bar tổng thể

- `Access`: Chung
- `Primary goal`: Điều hướng 5 tab chính của ứng dụng

```text
┌──────────────────────────────┐
│                              │
│        Nội dung màn          │
│                              │
│                              │
│                              │
├──────────────────────────────┤
│ Hôm nay | Luận giải |        │
│ Tương hợp | NumAI | Tôi      │
└──────────────────────────────┘
```

`Note`:
- Tab bar hiện tại được chốt gồm `Hôm nay`, `Luận giải`, `Tương hợp`, `NumAI`, `Tôi`.

## 2. Tab `Hôm nay`

## Mục tiêu tab

- Trả lời nhanh trong `10 giây đầu`: `Hôm nay mình thế nào?` và `Hôm nay nên làm gì?`
- Không biến màn đầu thành một bài đọc dài.
- Các lớp `tháng`, `năm`, `giai đoạn active` chỉ là `context`, không chiếm trọng tâm màn đầu.

### Screen `TODAY-01` - Home tab `Hôm nay`

- `Access`: `Free preview`
- `Primary goal`: Cho user xem nhanh tình hình hôm nay

```text
┌──────────────────────────────┐
│ Hôm nay                 04/03│
│ Chào buổi sáng, Minh         │
├──────────────────────────────┤
│ HERO CARD: Hôm nay của bạn   │
│                              │
│ Hôm nay là ngày để chậm lại, │
│ tập trung và nói ít nhưng rõ.│
│                              │
│ Năng lượng hôm nay: 7/10     │
│ Nhịp ngày: Tĩnh - Quan sát   │
│                              │
│ [Xem sâu hôm nay]            │
├──────────────────────────────┤
│ ACTION CARD                  │
│ Nên làm / Nên tránh          │
│                              │
│ Nên làm                      │
│ • Hoàn thành 1 việc quan trọng│
│ • Giữ giao tiếp ngắn gọn     │
│                              │
│ Nên tránh                    │
│ • Quyết định vội             │
│ • Tranh luận cảm tính        │
├──────────────────────────────┤
│ BỐI CẢNH HIỆN TẠI            │
│                              │
│ Tháng này                    │
│ Tháng cá nhân 5              │
│ Từ khóa: Thay đổi            │
│ [Xem]                        │
│                              │
│ Năm nay                      │
│ Năm cá nhân 8                │
│ Từ khóa: Thành tựu           │
│ [Xem]                        │
│                              │
│ Giai đoạn active             │
│ Đỉnh cao 2 đang hoạt động    │
│ Thử thách 1 cần chú ý        │
│ [Xem]                        │
├──────────────────────────────┤
│ Hôm nay | Luận giải |        │
│ Tương hợp | NumAI | Tôi      │
└──────────────────────────────┘
```

`Note`:
- Màn đầu chỉ có `Hero card` và `Action card` là nội dung chính.
- `Tháng này`, `Năm nay`, `Giai đoạn active` chỉ nên là card tóm tắt.
- Free user xem bản ngắn, PRO hoặc Soul Point mới mở sâu phần chi tiết.
- Các card này nên dẫn sang màn detail riêng, không bung toàn bộ nội dung dài ngay tại home.

### Screen `TODAY-02` - `Xem sâu hôm nay`

- `Access`: `PRO` hoặc `Soul Point`
- `Primary goal`: Giải thích chi tiết hơn về ngày cá nhân và insight hôm nay

```text
┌──────────────────────────────┐
│ < Hôm nay                    │
│ Xem sâu hôm nay              │
├──────────────────────────────┤
│ Ngày cá nhân 3               │
│                              │
│ Diễn giải chi tiết:          │
│ Hôm nay thuận cho biểu đạt,  │
│ kết nối, chia sẻ và sáng tạo.│
│ Nhưng dễ phân tán nếu ôm quá │
│ nhiều việc cùng lúc.         │
├──────────────────────────────┤
│ Gợi ý thêm                   │
│ • Ưu tiên việc cần sáng tạo  │
│ • Chủ động nói chuyện rõ ý   │
│ • Tránh dàn trải năng lượng  │
├──────────────────────────────┤
│ Mở bằng: PRO / Soul Point    │
└──────────────────────────────┘
```

`Note`:
- Đây là màn đào sâu của `Ngày cá nhân`.
- Có thể mở dưới dạng push screen hoặc bottom sheet full-screen.

### Screen `TODAY-03` - `Tháng này`

- `Access`: `PRO` hoặc `Soul Point`
- `Primary goal`: Giải thích trọng tâm tháng hiện tại

```text
┌──────────────────────────────┐
│ < Hôm nay                    │
│ Tháng này                    │
├──────────────────────────────┤
│ Tháng cá nhân 5              │
│ Từ khóa: Thay đổi            │
├──────────────────────────────┤
│ Trọng tâm tháng này          │
│ • Linh hoạt hơn              │
│ • Mở ra trải nghiệm mới      │
│ • Không cố giữ mọi thứ cũ    │
├──────────────────────────────┤
│ Điều cần ưu tiên             │
│ • Thử cách tiếp cận mới      │
│ • Điều chỉnh kế hoạch nhanh  │
├──────────────────────────────┤
│ Mở bằng: PRO / Soul Point    │
└──────────────────────────────┘
```

`Note`:
- Màn này giúp user hiểu `context` của tháng, không cạnh tranh sự chú ý với `Hôm nay`.
- Đây là màn detail riêng, có thể dùng content generate và cache theo `year-month`.

### Screen `TODAY-04` - `Năm nay`

- `Access`: `PRO` hoặc `Soul Point`
- `Primary goal`: Giải thích chủ đề của năm cá nhân

```text
┌──────────────────────────────┐
│ < Hôm nay                    │
│ Năm nay                      │
├──────────────────────────────┤
│ Năm cá nhân 8                │
│ Từ khóa: Thành tựu           │
├──────────────────────────────┤
│ Chủ đề năm hiện tại          │
│ • Tập trung kết quả          │
│ • Quản trị nguồn lực         │
│ • Xây nền cho bước tiến lớn  │
├──────────────────────────────┤
│ Bài học cần ưu tiên          │
│ • Kỷ luật                    │
│ • Trách nhiệm                │
│ • Cân bằng tham vọng         │
├──────────────────────────────┤
│ Mở bằng: PRO / Soul Point    │
└──────────────────────────────┘
```

`Note`:
- Dùng ngôn ngữ định hướng và tóm lược, không trình bày như “bài luận”.
- Đây là màn detail riêng, có thể dùng content generate và cache theo `year`.

### Screen `TODAY-05` - `Giai đoạn active`

- `Access`: `PRO` hoặc `Soul Point`
- `Primary goal`: Giải thích đỉnh cao và thử thách hiện đang tác động

```text
┌──────────────────────────────┐
│ < Hôm nay                    │
│ Giai đoạn active             │
├──────────────────────────────┤
│ Đỉnh cao hiện tại            │
│ Peak 2 đang active           │
│ Từ khóa: Hợp tác - trưởng thành│
├──────────────────────────────┤
│ Thử thách hiện tại           │
│ Challenge 1 đang active      │
│ Từ khóa: Cái tôi - chủ động  │
├──────────────────────────────┤
│ Diễn giải                    │
│ Đây là giai đoạn vừa học cách│
│ đi cùng người khác, vừa phải │
│ tự đứng vững bằng quyết định │
│ của riêng mình.              │
├──────────────────────────────┤
│ Mở bằng: PRO / Soul Point    │
└──────────────────────────────┘
```

`Note`:
- Màn này là lớp `context sâu`, không nên nằm ở top của tab `Hôm nay`.
- Đây là màn detail riêng, có thể dùng content generate và cache theo `phase key`.

### Screen `TODAY-06` - Sheet mở khóa `PRO / Soul Point`

- `Access`: Chung
- `Primary goal`: Cho user chọn cách mở nội dung sâu

```text
┌──────────────────────────────┐
│ Xem sâu hôm nay              │
├──────────────────────────────┤
│ Mở nội dung chi tiết theo 1  │
│ trong 2 cách sau:            │
│                              │
│ [Nâng cấp PRO]               │
│ Xem full tab Hôm nay         │
│                              │
│ [Dùng 10 Soul Point]         │
│ Mở sâu nội dung hôm nay      │
│                              │
│ Soul Point hiện có: 24       │
│ [Hủy]                        │
└──────────────────────────────┘
```

`Note`:
- Sheet này chỉ áp dụng cho các màn chi tiết trong `Hôm nay`.

## 3. Tab `Luận giải`

## Mục tiêu tab

- Trả lời câu hỏi `Tôi là ai?`
- Toàn bộ tab này đang được định hướng `Free`.
- Phần này là vùng đọc hồ sơ nền tảng, dùng lại lâu dài.

### Screen `READ-01` - Home tab `Luận giải`

- `Access`: `Free`
- `Primary goal`: Điều hướng 4 nhóm life-based

```text
┌──────────────────────────────┐
│ Luận giải                    │
│ Hồ sơ nền tảng của bạn       │
├──────────────────────────────┤
│ [Chỉ số cốt lõi]             │
│ Số chủ đạo, linh hồn,        │
│ nhân cách, biểu đạt          │
├──────────────────────────────┤
│ [Biểu đồ và ma trận]         │
│ Biểu đồ ngày sinh, Matrix    │
│ Aspect Detail                │
├──────────────────────────────┤
│ [Lộ trình cuộc đời]          │
│ 4 đỉnh cao, 4 thử thách      │
├──────────────────────────────┤
│ [Chân dung cá nhân]          │
│ Tính cách, giao tiếp,        │
│ tình cảm, công việc          │
├──────────────────────────────┤
│ Hôm nay | Luận giải |        │
│ Tương hợp | NumAI | Tôi      │
└──────────────────────────────┘
```

`Note`:
- Đây là màn menu cấp 1 của tab `Luận giải`.
- Mỗi item là một entry point vào một cụm nội dung rõ ràng.

### Screen `READ-02` - `Chỉ số cốt lõi`

- `Access`: `Free`
- `Primary goal`: Hiển thị các số nền tảng quan trọng nhất

```text
┌──────────────────────────────┐
│ < Luận giải                  │
│ Chỉ số cốt lõi               │
├──────────────────────────────┤
│ Số chủ đạo                   │
│ 7                            │
│ Từ khóa: Chiêm nghiệm        │
│ [Xem chi tiết]               │
├──────────────────────────────┤
│ Số biểu đạt                  │
│ 3                            │
│ Từ khóa: Biểu đạt            │
│ [Xem chi tiết]               │
├──────────────────────────────┤
│ Số linh hồn                  │
│ 2                            │
│ Từ khóa: Kết nối             │
│ [Xem chi tiết]               │
├──────────────────────────────┤
│ Số nhân cách                 │
│ 1                            │
│ Từ khóa: Chủ động            │
│ [Xem chi tiết]               │
└──────────────────────────────┘
```

`Note`:
- Có thể dùng list card hoặc accordion.
- Trên mobile, mỗi chỉ số nên có `từ khóa` và `1 câu tóm tắt` trước khi đi vào detail.

### Screen `READ-03` - `Biểu đồ và ma trận`

- `Access`: `Free`
- `Primary goal`: Cho user xem nhanh cấu trúc biểu đồ ngày sinh và entry vào phân tích sâu

```text
┌──────────────────────────────┐
│ < Luận giải                  │
│ Biểu đồ và ma trận           │
├──────────────────────────────┤
│ BIỂU ĐỒ NGÀY SINH            │
│ 1 | 4 | 7                    │
│ 2 | - | 8                    │
│ 3 | - | 9                    │
├──────────────────────────────┤
│ Các số mạnh, yếu, thiếu      │
│ Mạnh: 1, 7                   │
│ Thiếu: 5, 6                  │
│ [Xem chi tiết]               │
├──────────────────────────────┤
│ Matrix Aspect Detail         │
│ Trục thể chất, cảm xúc,      │
│ trí tuệ, mũi tên nổi bật     │
│ [Đi sâu]                     │
└──────────────────────────────┘
```

`Note`:
- Màn này là overview, không cố dồn toàn bộ diễn giải lên cùng một view.

### Screen `READ-04` - `Matrix Aspect Detail`

- `Access`: `Free`
- `Primary goal`: Đi sâu vào các trục và mũi tên nổi bật trong ma trận

```text
┌──────────────────────────────┐
│ < Biểu đồ và ma trận         │
│ Matrix Aspect Detail         │
├──────────────────────────────┤
│ Trục Thể chất                │
│ Mạnh ở tính thực tế và hành  │
│ động khi đã rõ mục tiêu      │
│ [Xem chi tiết]               │
├──────────────────────────────┤
│ Trục Cảm xúc                 │
│ Dễ giữ cảm xúc bên trong,    │
│ cần thời gian để mở lòng     │
│ [Xem chi tiết]               │
├──────────────────────────────┤
│ Trục Trí tuệ                 │
│ Thiên về quan sát và phân    │
│ tích trước khi quyết định    │
│ [Xem chi tiết]               │
├──────────────────────────────┤
│ Mũi tên nổi bật              │
│ Quyết tâm, nhạy cảm, ...     │
│ [Xem chi tiết]               │
└──────────────────────────────┘
```

`Note`:
- Đây là màn tập trung cho `Matrix Aspect Detail`.
- Nếu cần, về sau có thể tách từng trục thành màn con riêng.

### Screen `READ-05` - `Lộ trình cuộc đời`

- `Access`: `Free`
- `Primary goal`: Hiển thị tổng quan 4 đỉnh cao và 4 thử thách

```text
┌──────────────────────────────┐
│ < Luận giải                  │
│ Lộ trình cuộc đời            │
├──────────────────────────────┤
│ 4 ĐỈNH CAO CUỘC ĐỜI          │
│ Peak 1 | 24-32 | Số 3        │
│ Peak 2 | 33-41 | Số 8        │
│ Peak 3 | 42-50 | Số 2        │
│ Peak 4 | 51+   | Số 6        │
├──────────────────────────────┤
│ 4 THỬ THÁCH CUỘC ĐỜI         │
│ C1 | Chủ động                │
│ C2 | Kỷ luật                 │
│ C3 | Cảm xúc                 │
│ C4 | Buông kiểm soát         │
├──────────────────────────────┤
│ [Xem diễn giải từng giai đoạn]│
└──────────────────────────────┘
```

`Note`:
- Đây là màn lifetime nhưng có chiều thời gian.
- Dùng timeline hoặc list giai đoạn đều được.

### Screen `READ-06` - `Chân dung cá nhân`

- `Access`: `Free`
- `Primary goal`: Dịch toàn bộ bộ số sang ngôn ngữ đời sống

```text
┌──────────────────────────────┐
│ < Luận giải                  │
│ Chân dung cá nhân            │
├──────────────────────────────┤
│ Tổng quan tính cách          │
│ Bạn là người sâu sắc, quan   │
│ sát kỹ và ít mở lòng vội.    │
├──────────────────────────────┤
│ Điểm mạnh nổi bật            │
│ • Phân tích tốt              │
│ • Có chiều sâu nội tâm       │
│ • Kiên định                  │
├──────────────────────────────┤
│ Điểm cần cân bằng            │
│ • Dễ tự cô lập               │
│ • Dễ nghĩ quá nhiều          │
├──────────────────────────────┤
│ Giao tiếp | Tình cảm |       │
│ Công việc                    │
└──────────────────────────────┘
```

`Note`:
- Đây là phần dễ đọc nhất trong `Luận giải`.
- Nên trình bày theo card ngắn, không dùng những block text quá dài.

## 4. Tab `Tương hợp`

## Mục tiêu tab

- Cho user chọn một hồ sơ khác để so với hồ sơ hiện tại.
- Trả lời `mình hợp ở đâu`, `dễ lệch ở đâu`, `nên chú ý gì`.

### Screen `MATCH-01` - Home tab `Tương hợp`

- `Access`: `Free preview` hoặc `PRO` tùy chiến lược sau này
- `Primary goal`: Chọn người để so sánh

```text
┌──────────────────────────────┐
│ Tương hợp                    │
│ So với ai hôm nay?           │
├──────────────────────────────┤
│ Hồ sơ của bạn                │
│ Minh - 12/08/1998            │
├──────────────────────────────┤
│ Chọn hồ sơ đối chiếu         │
│ [Người yêu]                  │
│ [Bạn thân]                   │
│ [Mẹ]                         │
│ [+ Thêm hồ sơ mới]           │
├──────────────────────────────┤
│ [Bắt đầu so sánh]            │
├──────────────────────────────┤
│ Hôm nay | Luận giải |        │
│ Tương hợp | NumAI | Tôi      │
└──────────────────────────────┘
```

`Note`:
- Màn này cần rất rõ `hồ sơ của bạn` và `hồ sơ đối chiếu`.

### Screen `MATCH-02` - Kết quả `Tương hợp`

- `Access`: `Free preview` hoặc `PRO`
- `Primary goal`: Trả kết quả tương hợp nền tảng và diễn giải mối quan hệ

```text
┌──────────────────────────────┐
│ < Tương hợp                  │
│ Minh x Lan                   │
├──────────────────────────────┤
│ Mức độ tương hợp             │
│ 78 / 100                     │
│ Khá hòa hợp                  │
├──────────────────────────────┤
│ Điểm hợp nhau                │
│ • Giao tiếp mềm              │
│ • Bổ sung cảm xúc            │
├──────────────────────────────┤
│ Điểm dễ xung đột             │
│ • Khác nhịp quyết định       │
│ • Một người nhanh, một người │
│   cần thời gian              │
├──────────────────────────────┤
│ Gợi ý cho mối quan hệ        │
│ • Nói rõ kỳ vọng             │
│ • Tránh ép quyết định nhanh  │
└──────────────────────────────┘
```

`Note`:
- Đây là màn diễn giải cơ bản.
- Nếu cần chiến lược monetization sâu hơn, có thể cắt `Điểm hợp`, `Xung đột`, `Gợi ý` theo preview / full.

## 5. Tab `NumAI`

## Mục tiêu tab

- Là điểm đến riêng cho chatbot.
- User có thể hỏi thêm về bộ số, hồ sơ, thời điểm hiện tại và mối quan hệ.
- Giai đoạn hiện tại chưa có CTA từ tab khác sang đây.
- Tab này được mở cho cả `Free User` và `PRO User`.
- `Free User` cần tiêu hao `Soul Point` khi muốn gửi chat.

### Screen `AI-01` - Entry `NumAI`

- `Access`: `Free`
- `Primary goal`: Giới thiệu bot và định hướng câu hỏi

```text
┌──────────────────────────────┐
│ NumAI                        │
│ Trợ lý luận giải cá nhân     │
├──────────────────────────────┤
│ Bạn có thể hỏi về:           │
│ • Bộ số của bạn              │
│ • Hôm nay / tháng này        │
│ • Tình cảm / công việc       │
│ • Tương hợp với người khác   │
├──────────────────────────────┤
│ Gợi ý câu hỏi                │
│ [Tóm tắt tôi là người thế nào]│
│ [Hôm nay tôi nên chú ý gì]   │
│ [Tôi và người này hợp ở đâu] │
├──────────────────────────────┤
│ Soul Point hiện có: 24       │
│ Free user: chat bằng point   │
│ PRO: chat thuận tiện hơn     │
│ [Bắt đầu chat]               │
└──────────────────────────────┘
```

`Note`:
- Đây không còn là màn preview bị khóa.
- Đây là entry screen chung cho cả `Free User` và `PRO User`.

### Screen `AI-02` - Màn chat đang hoạt động

- `Access`: `Free` / `PRO`
- `Primary goal`: Chat với AI dựa trên hồ sơ numerology

```text
┌──────────────────────────────┐
│ < NumAI                      │
│ Đang trò chuyện              │
├──────────────────────────────┤
│ AI: Dựa trên bộ số của bạn,  │
│ hôm nay phù hợp với việc cần │
│ tập trung và giao tiếp rõ.   │
│                              │
│ Bạn: Vậy trong công việc tôi │
│ nên ưu tiên điều gì?         │
│                              │
│ AI: Bạn nên chọn 1 việc quan │
│ trọng nhất thay vì ôm nhiều  │
│ việc nhỏ cùng lúc.           │
├──────────────────────────────┤
│ Soul Point còn lại: 18       │
│ [Nhập câu hỏi của bạn...]    │
│ [Gửi - tốn 3 Soul Point]     │
└──────────────────────────────┘
```

`Note`:
- Màn chat nên có prompt input cố định ở đáy màn.
- Không cần nhồi nhiều chrome UI, ưu tiên tập trung vào hội thoại.
- Nếu là `PRO User`, phần CTA gửi chat không cần hiển thị logic tiêu hao `Soul Point`.
- Ở MVP, backend của `NumAI` dùng context payload cố định thay vì intent-based context retrieval.

### Screen `AI-03` - Sheet mở khóa chat `NumAI`

- `Access`: `Free`
- `Primary goal`: Cho `Free User` chọn giữa dùng `Soul Point` hoặc nâng cấp `PRO`

```text
┌──────────────────────────────┐
│ Gửi câu hỏi tới NumAI        │
├──────────────────────────────┤
│ Mỗi lượt chat của Free User  │
│ sẽ tiêu hao Soul Point.      │
│                              │
│ [Dùng 3 Soul Point]          │
│ Gửi 1 lượt chat ngay         │
│                              │
│ [Nâng cấp PRO]               │
│ Chat thuận tiện hơn mỗi ngày │
│                              │
│ Soul Point hiện có: 18       │
│ [Hủy]                        │
└──────────────────────────────┘
```

`Note`:
- Sheet này chỉ hiện với `Free User`.
- `PRO User` không cần đi qua bước này khi gửi chat.

## 6. Tab `Tôi`

## Mục tiêu tab

- Là hub cho tài khoản, hồ sơ, gói dịch vụ và cài đặt.
- Thay cho việc dùng một tab tên `Settings`.

### Screen `ME-01` - Home tab `Tôi`

- `Access`: Chung
- `Primary goal`: Điều hướng phần tài khoản và quản lý cá nhân

```text
┌──────────────────────────────┐
│ Tôi                          │
├──────────────────────────────┤
│ Hồ sơ của tôi                │
│ Minh                         │
│ [Xem hồ sơ]                  │
├──────────────────────────────┤
│ [Danh sách hồ sơ đã lưu]     │
│ [Gói dịch vụ]                │
│ [Cài đặt]                    │
│ [Thông báo]                  │
│ [Quyền riêng tư]             │
│ [Trợ giúp]                   │
├──────────────────────────────┤
│ Hôm nay | Luận giải |        │
│ Tương hợp | NumAI | Tôi      │
└──────────────────────────────┘
```

`Note`:
- Đây là màn hub, không cần quá nhiều nội dung ngay lúc đầu.

### Screen `ME-02` - `Hồ sơ của tôi`

- `Access`: Chung
- `Primary goal`: Hiển thị thông tin hồ sơ chính để luận giải

```text
┌──────────────────────────────┐
│ < Tôi                        │
│ Hồ sơ của tôi                │
├──────────────────────────────┤
│ Họ tên dùng để luận          │
│ Nguyễn Văn Minh              │
├──────────────────────────────┤
│ Ngày sinh                    │
│ 12/08/1998                   │
├──────────────────────────────┤
│ Giới tính                    │
│ Nam                          │
├──────────────────────────────┤
│ [Chỉnh sửa hồ sơ]            │
└──────────────────────────────┘
```

`Note`:
- Đây là hồ sơ chính làm nền cho toàn bộ luận giải.

### Screen `ME-03` - `Danh sách hồ sơ đã lưu`

- `Access`: Chung hoặc gắn logic monetization sau này
- `Primary goal`: Quản lý các hồ sơ người thân / người khác

```text
┌──────────────────────────────┐
│ < Tôi                        │
│ Hồ sơ đã lưu                 │
├──────────────────────────────┤
│ [Minh - Hồ sơ chính]         │
│ [Lan - Người yêu]            │
│ [Mẹ]                         │
│ [Bạn thân]                   │
│ [+ Thêm hồ sơ mới]           │
└──────────────────────────────┘
```

`Note`:
- Màn này sẽ liên quan trực tiếp tới `Tương hợp`.

### Screen `ME-04` - `Gói dịch vụ`

- `Access`: Chung
- `Primary goal`: Quản lý và nâng cấp gói

```text
┌──────────────────────────────┐
│ < Tôi                        │
│ Gói dịch vụ                  │
├──────────────────────────────┤
│ Gói hiện tại                 │
│ Free                         │
├──────────────────────────────┤
│ VIP PRO                      │
│ • Full tab Hôm nay           │
│ • NumAI                      │
│ • Mở sâu nội dung            │
│ [Nâng cấp ngay]              │
└──────────────────────────────┘
```

`Note`:
- Gắn trực tiếp với mô hình monetization đã chốt.

### Screen `ME-05` - `Cài đặt`

- `Access`: Chung
- `Primary goal`: Các tùy chọn ứng dụng cơ bản

```text
┌──────────────────────────────┐
│ < Tôi                        │
│ Cài đặt                      │
├──────────────────────────────┤
│ [Thông báo hằng ngày]        │
│ [Ngôn ngữ]                   │
│ [Múi giờ]                    │
│ [Chính sách riêng tư]        │
│ [Điều khoản sử dụng]         │
└──────────────────────────────┘
```

`Note`:
- Phần này hỗ trợ vận hành, không phải value layer chính của app.

## 7. Danh sách màn hình tổng hợp

### `Hôm nay`
- `TODAY-01` Home tab `Hôm nay`
- `TODAY-02` Xem sâu hôm nay
- `TODAY-03` Tháng này
- `TODAY-04` Năm nay
- `TODAY-05` Giai đoạn active
- `TODAY-06` Sheet mở khóa PRO / Soul Point

### `Luận giải`
- `READ-01` Home tab `Luận giải`
- `READ-02` Chỉ số cốt lõi
- `READ-03` Biểu đồ và ma trận
- `READ-04` Matrix Aspect Detail
- `READ-05` Lộ trình cuộc đời
- `READ-06` Chân dung cá nhân

### `Tương hợp`
- `MATCH-01` Home tab `Tương hợp`
- `MATCH-02` Kết quả tương hợp

### `NumAI`
- `AI-01` Entry NumAI
- `AI-02` Màn chat đang hoạt động
- `AI-03` Sheet mở khóa chat NumAI

### `Tôi`
- `ME-01` Home tab `Tôi`
- `ME-02` Hồ sơ của tôi
- `ME-03` Danh sách hồ sơ đã lưu
- `ME-04` Gói dịch vụ
- `ME-05` Cài đặt

## 8. Ghi chú review

Khi review tài liệu này, nên tập trung check 4 thứ:

1. `Tab Hôm nay` đã đủ nhẹ chưa, đặc biệt trong `10 giây đầu tiên`.
2. `Luận giải` đã chia nhóm đủ rõ chưa.
3. `NumAI` có nên locked preview hay mở một phần cho free hay không.
   - Quyết định hiện tại: tab `NumAI` mở cho cả free user.
   - `Free User` dùng `Soul Point` cho từng lượt chat.
   - `PRO User` có trải nghiệm chat thuận tiện hơn.
4. `Tab Tôi` hiện đã đủ scope cho MVP chưa hay cần rút gọn thêm.
