# Numverse User Flow / UX Logic

## Mục đích tài liệu

Tài liệu này mô tả:
- `user flow` chính của ứng dụng `Numverse`
- `UX logic` giữa các tab, các màn, và các trạng thái người dùng
- các điều kiện mở khóa giữa `Free`, `PRO`, và `Soul Point`

Tài liệu này dùng để nối 2 file:
- [NUMVERSE_PRODUCT_SUMMARY.md](/Users/uranidev/Documents/Numverse/NUMVERSE_PRODUCT_SUMMARY.md)
- [NUMVERSE_MOBILE_WIREFRAMES_LOFI.md](/Users/uranidev/Documents/Numverse/NUMVERSE_MOBILE_WIREFRAMES_LOFI.md)

## 1. Nguyên tắc UX cốt lõi

### 1.1. Giá trị của app được chia làm 2 lớp
- `Life-based`: giúp người dùng hiểu `mình là ai`
- `Time-based`: giúp người dùng hiểu `hiện tại mình đang ở đâu`

### 1.2. Không paywall quá sớm
- User cần được thấy giá trị thật trước khi phải trả tiền.
- `Luận giải` là vùng giá trị mở để tạo `aha moment`.
- `Hôm nay` và `NumAI` là nơi dùng để upsell.

### 1.3. Tab `Hôm nay` phải nhẹ
- 10 giây đầu chỉ nên trả lời:
  - `Hôm nay mình thế nào?`
  - `Hôm nay nên làm gì / tránh gì?`
- Các lớp `tháng`, `năm`, `giai đoạn active` chỉ là context.

### 1.4. `NumAI` là destination riêng
- Không đặt `NumAI` như CTA rải rác ở các tab khác trong giai đoạn hiện tại.
- User chủ động vào tab `NumAI` khi muốn hỏi thêm.

### 1.5. `Soul Point` là cầu nối, không phải đường thay thế `PRO`
- `Soul Point` cho phép user free dùng thử từng lượt.
- `PRO` vẫn là lựa chọn thuận tiện hơn cho usage thường xuyên.

## 2. Trạng thái người dùng

Có 3 trạng thái UX chính:

### 2.1. `Guest / First-time user`
- Chưa có hồ sơ chính
- Chưa có dữ liệu để luận giải

### 2.2. `Free user`
- Đã có hồ sơ chính
- Được xem full `Luận giải`
- Được xem nhẹ `Hôm nay`
- Được vào `NumAI` nhưng gửi chat bằng `Soul Point`

### 2.3. `PRO user`
- Đã có hồ sơ chính
- Được xem full `Hôm nay`
- Được dùng `NumAI` thuận tiện hơn
- Có thể được mở rộng thêm các quyền khác sau này

## 3. Điều hướng tổng thể

Tab bar chính:
1. `Hôm nay`
2. `Luận giải`
3. `Tương hợp`
4. `NumAI`
5. `Tôi`

Logic tổng:
- Sau khi có hồ sơ chính, app mở vào tab `Hôm nay` mặc định.
- Từ mọi tab, user có thể chuyển ngang sang tab khác bằng tab bar.
- Bên trong mỗi tab, user đi theo `list -> detail -> paywall/sheet nếu cần`.

## 4. Flow tổng quát của ứng dụng

### Flow `GLOBAL-01` - First open

```text
Mở app lần đầu
-> chưa có hồ sơ chính
-> tạo hồ sơ cá nhân
-> nhập họ tên + ngày sinh
-> hệ thống tính toàn bộ dữ liệu numerology
-> sinh kết quả life-based + time-based
-> vào app shell
-> mở tab "Hôm nay"
```

`UX logic`:
- App chỉ thực sự có giá trị khi đã có `hồ sơ chính`.
- Hồ sơ chính là nền cho `Luận giải`, `Hôm nay`, `NumAI`, `Tương hợp`.
- Toàn bộ calculation diễn ra sau khi user nhập đủ dữ liệu nền.

### Flow `GLOBAL-02` - Returning user

```text
Mở app
-> đã có hồ sơ chính
-> load dữ liệu hôm nay + hồ sơ numerology
-> vào tab "Hôm nay"
```

`UX logic`:
- `Hôm nay` là entry point mặc định cho người dùng quay lại.
- Đây là nơi tạo thói quen hằng ngày.

## 5. User Flow theo từng tab

## 5.1. Tab `Hôm nay`

### Mục tiêu UX
- Dùng như `morning check-in`
- Trả lời nhanh trong thời gian ngắn
- Tách `quick read` và `deep read`

### Flow `TODAY-FLOW-01` - Free user mở tab `Hôm nay`

```text
User vào tab "Hôm nay"
-> thấy Hero card
-> thấy Action card
-> thấy Bối cảnh hiện tại
-> nếu chỉ đọc nhanh
   -> thoát hoặc chuyển tab khác
-> nếu muốn xem sâu
   -> chọn "Xem sâu hôm nay" / "Tháng này" / "Năm nay" / "Giai đoạn active"
   -> mở sheet chọn PRO hoặc Soul Point
```

`UX logic`:
- Free user luôn nhận được một phiên bản có ích, không bị chặn trắng màn hình.
- Các phần sâu hơn là `optional deepening`, không phải điều kiện để hiểu màn đầu.
- `Tháng này`, `Năm nay`, `Giai đoạn active` là các màn detail riêng, không chỉ là card bung dài từ màn home.

### Flow `TODAY-FLOW-02` - PRO user mở tab `Hôm nay`

```text
User vào tab "Hôm nay"
-> thấy Hero card
-> thấy Action card
-> thấy Bối cảnh hiện tại
-> nhấn vào bất kỳ phần nào cần xem sâu
-> vào detail trực tiếp
```

`UX logic`:
- PRO không nên bị thêm friction không cần thiết.
- Detail của `Ngày`, `Tháng`, `Năm`, `Giai đoạn active` mở thẳng.
- Các detail này có thể có dữ liệu generate và cache riêng theo từng `time bucket`.

### Flow `TODAY-FLOW-03` - Free user mở sâu bằng Soul Point

```text
Từ TODAY-01
-> user nhấn "Xem sâu hôm nay"
-> mở TODAY-06
-> chọn "Dùng Soul Point"
-> kiểm tra số point hiện có
-> đủ point
   -> trừ point
   -> mở màn detail tương ứng
-> không đủ point
   -> hiển thị nhắc tích điểm hoặc nâng cấp PRO
```

`UX logic`:
- Soul Point chỉ mở `lượt xem sâu lẻ`
- Không mở khóa vĩnh viễn
- Nếu point không đủ, không dead end; phải luôn có nhánh tiếp theo

### Flow `TODAY-FLOW-04` - Cấu trúc nội dung trong tab `Hôm nay`

```text
TODAY-01 Home
-> TODAY-02 Xem sâu hôm nay
-> TODAY-03 Tháng này
-> TODAY-04 Năm nay
-> TODAY-05 Giai đoạn active
-> TODAY-06 Sheet mở khóa PRO / Soul Point
```

`UX logic`:
- `TODAY-01` là quick layer
- `TODAY-02` đến `TODAY-05` là deep layer
- `TODAY-06` là decision layer

## 5.2. Tab `Luận giải`

### Mục tiêu UX
- Là vùng đọc hồ sơ nền tảng
- Tất cả đều `Free`
- Điều hướng theo nhóm nội dung, không dồn toàn bộ lên một màn

### Flow `READ-FLOW-01` - Vào tab `Luận giải`

```text
User vào tab "Luận giải"
-> thấy 4 nhóm chính
   -> Chỉ số cốt lõi
   -> Biểu đồ và ma trận
   -> Lộ trình cuộc đời
   -> Chân dung cá nhân
-> chọn một nhóm để đi sâu
```

`UX logic`:
- Đây là màn menu cấp 1 của vùng life-based.
- Không nên ép user đọc theo thứ tự cứng.

### Flow `READ-FLOW-02` - Nhánh `Chỉ số cốt lõi`

```text
READ-01
-> chọn "Chỉ số cốt lõi"
-> READ-02
-> chọn từng chỉ số
-> xem chi tiết của từng chỉ số
-> back về READ-02 hoặc READ-01
```

`UX logic`:
- User có thể đọc từng chỉ số riêng lẻ
- Không bắt buộc cuộn qua tất cả chỉ số trong một trang quá dài

### Flow `READ-FLOW-03` - Nhánh `Biểu đồ và ma trận`

```text
READ-01
-> chọn "Biểu đồ và ma trận"
-> READ-03
-> xem overview biểu đồ
-> chọn "Matrix Aspect Detail"
-> READ-04
-> xem các trục và mũi tên nổi bật
```

`UX logic`:
- `READ-03` là overview
- `READ-04` là màn đi sâu
- Phần phân tích sâu được tách khỏi biểu đồ overview để giảm cognitive load

### Flow `READ-FLOW-04` - Nhánh `Lộ trình cuộc đời`

```text
READ-01
-> chọn "Lộ trình cuộc đời"
-> READ-05
-> xem tổng quan 4 đỉnh cao và 4 thử thách
-> nếu cần, đi tiếp vào diễn giải từng giai đoạn
```

`UX logic`:
- Đây là content lifetime nhưng có logic thời gian.
- Màn đầu của nhánh này chỉ nên cho `overview`, không bung hết mọi diễn giải.

### Flow `READ-FLOW-05` - Nhánh `Chân dung cá nhân`

```text
READ-01
-> chọn "Chân dung cá nhân"
-> READ-06
-> đọc tổng quan tính cách
-> đọc điểm mạnh / điểm cân bằng
-> đi tiếp vào giao tiếp / tình cảm / công việc nếu có
```

`UX logic`:
- Đây là phần “dịch” numerology sang ngôn ngữ đời sống.
- Nên là phần dễ tiêu thụ nhất trong tab `Luận giải`.

## 5.3. Tab `Tương hợp`

### Mục tiêu UX
- Cho user so một hồ sơ khác với hồ sơ chính
- Trọng tâm là `chọn đúng người` trước, `đọc kết quả` sau

### Flow `MATCH-FLOW-01` - Chọn người để so sánh

```text
User vào tab "Tương hợp"
-> thấy hồ sơ chính của mình
-> chọn hồ sơ đối chiếu từ danh sách đã lưu
-> hoặc thêm hồ sơ mới
-> nhấn "Bắt đầu so sánh"
-> vào màn kết quả
```

`UX logic`:
- `Tương hợp` không thể hoạt động nếu chưa có hồ sơ đối chiếu.
- Nếu chưa có hồ sơ đối chiếu, CTA chính phải là `Thêm hồ sơ mới`.

### Flow `MATCH-FLOW-02` - Xem kết quả tương hợp

```text
MATCH-01
-> MATCH-02
-> xem mức độ tương hợp
-> xem điểm hợp nhau
-> xem điểm dễ xung đột
-> xem gợi ý cho mối quan hệ
```

`UX logic`:
- Thứ tự nên đi từ `điểm số / nhận định chung`
- sau đó tới `điểm hợp`
- rồi tới `xung đột`
- cuối cùng là `gợi ý`

## 5.4. Tab `NumAI`

### Mục tiêu UX
- Là nơi user hỏi sâu hơn về chính mình
- Mở cho cả `Free` và `PRO`
- `Free` trả bằng `Soul Point` theo lượt
- `PRO` dùng thuận tiện hơn

### Flow `AI-FLOW-01` - Vào tab `NumAI`

```text
User vào tab "NumAI"
-> thấy AI-01
-> đọc bot có thể làm gì
-> xem gợi ý câu hỏi
-> nhấn "Bắt đầu chat"
-> vào AI-02
```

`UX logic`:
- Màn đầu của `NumAI` phải cho user hiểu ngay:
  - bot biết gì
  - bot trả lời về chủ đề gì
  - bot dựa trên dữ liệu nào

### Flow `AI-FLOW-02` - Free user gửi chat

```text
AI-01
-> AI-02
-> user nhập câu hỏi
-> nhấn gửi
-> hệ thống kiểm tra Soul Point
-> đủ point
   -> mở AI-03 hoặc confirm inline
   -> trừ point
   -> gửi câu hỏi
   -> hiển thị câu trả lời
-> không đủ point
   -> hiện lựa chọn tích điểm hoặc nâng cấp PRO
```

`UX logic`:
- Free user vẫn vào được chat screen
- Friction chỉ xuất hiện ở hành động `gửi`
- Điều này tốt hơn việc khóa cả tab từ đầu

### Flow `AI-FLOW-03` - PRO user gửi chat

```text
AI-01
-> AI-02
-> user nhập câu hỏi
-> nhấn gửi
-> gửi thẳng câu hỏi
-> hiển thị câu trả lời
```

`UX logic`:
- PRO không nên qua bước confirm bằng Soul Point.
- Cảm giác phải là `liền mạch`, `thân thiện`, `truy cập ngay`.

### Flow `AI-FLOW-04` - Context payload MVP của `NumAI`

```text
NumAI nhận ngữ cảnh từ:
-> thread_summary
-> 20 tin nhắn gần nhất
-> active_profile
-> snapshot_facts
-> user_question
```

`Backend logic`:
- Edge Function lấy `active prompt template` từ database theo `prompt_key` của chức năng chat.
- Prompt template được version hóa để hỗ trợ đổi prompt, rollback, và audit mà không cần deploy app.
- Mỗi request chat nên log lại `prompt_template_id` và `prompt_version` vào generation run.

`UX logic`:
- Ở MVP, chatbot dùng một payload context cố định cho mọi request.
- Chưa dùng `intent detection` để bơm thêm `daily_facts` hoặc `compatibility_facts`.
- AI vẫn phải bám vào `snapshot_facts` và mạch hội thoại gần nhất để trả lời.

## 5.5. Tab `Tôi`

### Mục tiêu UX
- Là hub vận hành và quản lý cá nhân
- Không cạnh tranh vai trò với các tab value chính

### Flow `ME-FLOW-01` - Vào tab `Tôi`

```text
User vào tab "Tôi"
-> thấy các mục quản lý
   -> Hồ sơ của tôi
   -> Hồ sơ đã lưu
   -> Gói dịch vụ
   -> Cài đặt
   -> mục khác
-> chọn một mục để vào detail
```

`UX logic`:
- `Tôi` là hub
- Mỗi item là một nhánh quản trị riêng

### Flow `ME-FLOW-02` - Hồ sơ chính

```text
ME-01
-> chọn "Hồ sơ của tôi"
-> ME-02
-> xem / sửa dữ liệu dùng để luận giải
```

`UX logic`:
- Thay đổi dữ liệu hồ sơ chính có thể ảnh hưởng toàn bộ kết quả numerology.
- Vì vậy đây là màn quản trị quan trọng.

### Flow `ME-FLOW-03` - Hồ sơ đã lưu

```text
ME-01
-> chọn "Danh sách hồ sơ đã lưu"
-> ME-03
-> xem hồ sơ người khác
-> thêm mới / chỉnh sửa / xóa
-> dùng cho tab Tương hợp
```

`UX logic`:
- Danh sách hồ sơ đã lưu là hạ tầng cho `Tương hợp`.
- Nếu không có màn này, `Tương hợp` sẽ bị đứt mạch sử dụng.

### Flow `ME-FLOW-04` - Gói dịch vụ

```text
ME-01
-> chọn "Gói dịch vụ"
-> ME-04
-> xem gói hiện tại
-> xem quyền lợi PRO
-> nâng cấp nếu muốn
```

`UX logic`:
- Đây là nơi user chủ động ra quyết định thanh toán.
- Ngoài tab này, paywall/sheet chỉ nên xuất hiện khi user chạm vào nội dung premium.

## 6. Decision Logic theo trạng thái truy cập

## 6.1. Logic của `Luận giải`

```text
Nếu đã có hồ sơ chính
-> cho vào toàn bộ tab Luận giải

Nếu chưa có hồ sơ chính
-> yêu cầu tạo hồ sơ trước
```

## 6.2. Logic của `Hôm nay`

```text
Nếu là Free
-> xem TODAY-01 bản nhẹ
-> mở sâu bằng PRO hoặc Soul Point

Nếu là PRO
-> xem TODAY-01
-> vào sâu trực tiếp
```

`Data logic`:
- `TODAY-01` dùng `daily preview cache` theo ngày.
- `TODAY-02` dùng detail theo ngày.
- `TODAY-03` dùng detail theo tháng hiện tại.
- `TODAY-04` dùng detail theo năm hiện tại.
- `TODAY-05` dùng detail theo `active phase` hiện tại.
- `TODAY-03`, `TODAY-04`, `TODAY-05` nên được generate lazy khi user mở màn detail, rồi cache lại cho lần sau.

## 6.3. Logic của `NumAI`

```text
Nếu là Free
-> vào được AI-01 và AI-02
-> khi gửi chat thì kiểm tra Soul Point
-> đủ point thì gửi
-> không đủ point thì hiện lựa chọn khác

Nếu là PRO
-> vào được AI-01 và AI-02
-> gửi chat trực tiếp
```

## 6.4. Logic của `Tương hợp`

```text
Nếu chưa có hồ sơ đối chiếu
-> điều hướng sang thêm hồ sơ mới

Nếu đã có hồ sơ đối chiếu
-> cho so sánh và xem kết quả
```

## 7. UX Logic của Soul Point

### 7.1. Nguồn point
- Điểm danh hằng ngày
- Streak
- Xem quảng cáo

### 7.2. Điểm dùng point
- Mở sâu `Hôm nay`
- Mở sâu `Tháng này`
- Mở sâu `Năm nay`
- Mở sâu `Giai đoạn active`
- Gửi chat trong `NumAI`

### 7.3. Quy tắc dùng point
- Point chỉ dùng để mở `lượt lẻ`
- Không mở khóa permanent
- Không nên đủ dồi dào tới mức làm `PRO` mất ý nghĩa

### 7.4. Trạng thái không đủ point

```text
User thực hiện hành động cần point
-> hệ thống kiểm tra số dư
-> nếu không đủ
   -> hiển thị:
      - số point đang có
      - số point cần thêm
      - cách nhận point
      - CTA nâng cấp PRO
```

`UX logic`:
- Không để user bị cụt luồng.
- Mọi dead end phải có ít nhất một nhánh tiếp.

## 8. Screen-to-Screen Map

### `Hôm nay`

```text
APP-01
-> TODAY-01
-> TODAY-02
-> TODAY-03
-> TODAY-04
-> TODAY-05

Từ TODAY-01 / TODAY-02 / TODAY-03 / TODAY-04 / TODAY-05
-> TODAY-06 khi cần mở khóa
```

### `Luận giải`

```text
APP-01
-> READ-01
-> READ-02
-> READ-03
-> READ-04
-> READ-05
-> READ-06
```

### `Tương hợp`

```text
APP-01
-> MATCH-01
-> MATCH-02
```

### `NumAI`

```text
APP-01
-> AI-01
-> AI-02
-> AI-03 khi free user gửi chat
```

### `Tôi`

```text
APP-01
-> ME-01
-> ME-02
-> ME-03
-> ME-04
-> ME-05
```

## 9. UX Priorities cho MVP

Nếu phải ưu tiên cho MVP, nên chốt theo thứ tự:

1. `Hôm nay` phải ngắn, rõ, dùng được ngay.
2. `Luận giải` phải có grouping rõ và dễ đọc.
3. `NumAI` phải có logic `Free bằng Soul Point / PRO dùng thẳng` thật mạch lạc.
4. `Tương hợp` phải có luồng thêm hồ sơ đối chiếu đủ rõ.
5. `Tôi` chỉ cần đủ cho quản trị cơ bản, không cần nặng.

## 10. Điểm cần review tiếp

1. App có landing vào `Hôm nay` sau onboarding hay không.
2. `Tương hợp` sẽ là free preview hay premium ngay từ MVP.
3. `NumAI` tính point theo `mỗi lượt chat`, `mỗi câu hỏi`, hay `mỗi phiên`.
4. `Soul Point` sẽ có giới hạn tích lũy tối đa hay không.
