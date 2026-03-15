# Numverse Numerology Formula Documentation

Tài liệu này mô tả công thức tính hiện tại đang chạy trong code Flutter (`lib/src/...`) cho từng nhóm con số.

## 1. Quy ước chung

### 1.1 Rút gọn số (`reduceToSingleDigit`)
- Source: `lib/src/helper/numerology_helper.dart`
- Quy tắc:
  1. Lấy trị tuyệt đối.
  2. Nếu `result > 9`, cộng các chữ số lại.
  3. Lặp đến khi `<= 9`.
  4. Nếu `preserveMaster = true` và `result` là `11`, `22`, `33` thì dừng sớm tại master number.

### 1.2 Bảng quy đổi chữ cái -> số (Pythagorean)
- Source: `lib/src/helper/numerology_helper.dart` (`_letterValue`)
- Mapping:
  - `1`: A J S
  - `2`: B K T
  - `3`: C L U
  - `4`: D M V
  - `5`: E N W
  - `6`: F O X
  - `7`: G P Y
  - `8`: H Q Z
  - `9`: I R

### 1.3 Chuẩn hóa tên
- Source: `lib/src/helper/numerology_helper.dart` (`_normalizeName`)
- Toàn bộ tên được upper-case và bỏ dấu tiếng Việt trước khi quy đổi chữ cái.

## 2. Nhóm Time-Life Numbers (thay đổi theo thời gian)

Source chính:
- `lib/src/ui/main/interactor/main_session_cubit.dart`
- `lib/src/core/model/profile_time_life_snapshot.dart`
- `lib/src/helper/numerology_helper.dart`

### 2.1 Universal Day Number (`universal_day`)
- Công thức:
  - `universalDay = reduce(day + month + year)`
- Hàm:
  - `NumerologyHelper.calculateUniversalDayNumber(date)`
- Refresh:
  - Qua ngày mới: `refreshAt = DateTime(year, month, day + 1)`

### 2.2 Lucky Number (`lucky_number`)
- Công thức:
  - `seed = day + month + year`
  - `luckyNumber = (seed % 9) + 1`
- Hàm:
  - `NumerologyHelper.luckyNumber(date)`
- Refresh:
  - Qua ngày mới.

### 2.3 Daily Message Number (`daily_message_number`)
- Công thức số nền:
  - Hiện tại map trực tiếp từ `universalDay`.
- Chọn template message:
  - `dayOfYear = date.difference(DateTime(year, 1, 0)).inDays`
  - `index = dayOfYear % templates.length`
- Hàm:
  - `DailyMessageBloc._buildState(...)`
  - `AssetNumerologyContentRepository.getDailyMessageTemplate(...)`
- Refresh:
  - Qua ngày mới.

### 2.4 Personal Year Number (`personal_year_number`)
- Công thức:
  - `personalYear = reduce(reduce(birthDay) + reduce(birthMonth) + reduce(currentYear))`
- Hàm:
  - `NumerologyHelper.calculatePersonalYearNumber(...)`
- Refresh:
  - Qua năm mới: `DateTime(year + 1, 1, 1)`

### 2.5 Personal Month Number (`personal_month_number`)
- Công thức:
  - `personalMonth = reduce(personalYear + currentMonth)`
- Hàm:
  - `NumerologyHelper.calculatePersonalMonthNumber(...)`
- Refresh:
  - Qua tháng mới: `DateTime(year, month + 1, 1)`

### 2.6 Personal Day Number (`personal_day_number`)
- Công thức:
  - `personalDay = reduce(personalMonth + currentDay)`
- Hàm:
  - `NumerologyHelper.calculatePersonalDayNumber(...)`
- Refresh:
  - Qua ngày mới.

### 2.7 Snapshot lưu trữ theo từng metric
- Mỗi metric lưu riêng:
  - `value`, `computedAt`, `refreshAt`
- Model:
  - `TimeLifeMetricSnapshot`
  - `ProfileTimeLifeSnapshot.metrics: Map<String, TimeLifeMetricSnapshot>`
- Khi `updateProfile`:
  - Snapshot của profile đó bị xóa để buộc tính lại.

## 3. Nhóm Core Numbers (tính theo profile, dùng lâu dài)

Source:
- `lib/src/helper/numerology_helper.dart`
- `lib/src/ui/core_numbers/interactor/core_numbers_bloc.dart`

### 3.1 Life Path Number
- Công thức:
  - `day = reduce(birthDay)`
  - `month = reduce(birthMonth)`
  - `year = reduce(birthYear)`
  - `lifePath = reduce(day + month + year, preserveMaster: true)`

### 3.2 Expression Number
- Công thức:
  - Chuẩn hóa tên -> map từng chữ cái theo bảng -> cộng tổng -> `reduce(total)`

### 3.3 Soul Urge Number
- Công thức:
  - Lấy nguyên âm `A,E,I,O,U` từ tên đã chuẩn hóa -> map số -> cộng tổng -> `reduce(total)`

### 3.4 Personality Number
- Công thức:
  - Lấy phụ âm từ tên đã chuẩn hóa -> map số -> cộng tổng -> `reduce(total)`

### 3.5 Mission Number
- Công thức:
  - `mission = reduce(lifePath + expression)`

## 4. Nhóm Chart Matrix

Source:
- `lib/src/helper/numerology_helper.dart`
- `lib/src/ui/chart_matrix/interactor/chart_matrix_bloc.dart`

### 4.1 Birth Chart (ma trận ngày sinh)
- Input string:
  - `'$day$month$year'` (không pad 0)
- Đếm tần suất chữ số `1..9` (bỏ `0`).

### 4.2 Name Chart (ma trận tên)
- Chuẩn hóa tên -> map chữ cái theo bảng số -> đếm tần suất `1..9`.

### 4.3 Axes
- Physical: `[1,4,7]`
- Mental: `[3,6,9]`
- Emotional: `[2,5,8]`
- `present = true` khi đủ cả 3 số trên trục.

### 4.4 Arrows
- determination: `[3,5,7]` đủ cả 3
- planning: `[1,2,3]` đủ cả 3
- willpower: `[4,5,6]` đủ cả 3
- activity: `[1,5,9]` đủ cả 3
- sensitivity: `[3,6,9]` đủ cả 3
- frustration: thiếu pattern `[4,5,6]`
- success: `[7,8,9]` đủ cả 3
- spirituality: `[1,5,9]` đủ cả 3 (đang cùng pattern với `activity`, theo code hiện tại)

### 4.5 Dominant Numbers
- `maxCount = max(frequency)`
- Nếu `maxCount <= 1` => không có dominant.
- Dominant là các số có `count == maxCount`.

## 5. Nhóm Life Path Cycles

Source:
- `lib/src/helper/numerology_helper.dart`
- `lib/src/ui/life_path/interactor/life_path_bloc.dart`

### 5.1 Tuổi hiện tại
- `age = currentYear - birthYear`
- Nếu chưa tới sinh nhật năm nay thì `age -= 1`.

### 5.2 Pinnacles (4 chu kỳ đỉnh cao)
- Input:
  - `day = birthDay`
  - `month = birthMonth`
  - `year = birthYear`
  - `lifePath = getLifePathNumber(birthDate)`
- Công thức:
  - `p1 = reduce(month + day, preserveMaster: true)`
  - `p2 = reduce(day + year, preserveMaster: true)`
  - `p3 = reduce(p1 + p2, preserveMaster: true)`
  - `p4 = reduce(month + year, preserveMaster: true)`
- Mốc tuổi:
  - `p1End = 36 - lifePath`
  - `p2End = p1End + 9`
  - `p3End = p2End + 9`
  - Chu kỳ 4: từ `p3End + 1` trở đi.

### 5.3 Challenges (4 chu kỳ thách thức)
- Input:
  - `day = reduce(birthDay)`
  - `month = reduce(birthMonth)`
  - `yearReduced = reduce(birthYear)`
  - `lifePath = getLifePathNumber(birthDate)`
- Công thức:
  - `c1 = abs(month - day)`
  - `c2 = abs(day - yearReduced)`
  - `c3 = abs(c1 - c2)`
  - `c4 = abs(month - yearReduced)`
- Mốc tuổi:
  - Dùng cùng boundary như Pinnacles (`36 - lifePath`, sau đó +9, +9).

## 6. Nhóm Angel Numbers

Source:
- `lib/src/ui/angel_numbers/interactor/angel_numbers_bloc.dart`

### 6.1 Digit Root (rút gọn dãy số thiên thần)
- `sum = tổng các chữ số`
- Lặp cộng chữ số đến khi còn 1 chữ số (`1..9`).

### 6.2 Nhận diện pattern
- Repeating:
  - Tất cả ký tự giống nhau.
- Mixed:
  - Lấy danh sách chữ số unique theo thứ tự xuất hiện.

### 6.3 Sinh nghĩa động
- Nếu có meaning cố định trong `_knownMeanings` thì dùng trực tiếp.
- Nếu không:
  - Dựa vào `digitRoot`, `isRepeating`, `firstDigit`, `lastDigit`, `uniqueDigits` để build text động.

## 7. Nhóm Compatibility / Comparison Score

Source:
- `lib/src/ui/comparison_result/interactor/comparison_result_bloc.dart`
- `lib/src/ui/compatibility/interactor/compatibility_bloc.dart`

### 7.1 Điểm cặp 2 số (`pairScore`)
- `diff = abs(first - second)` clamp `0..8`
- `scoreMap = [96, 90, 84, 78, 72, 66, 60, 54, 48]`
- `pairScore = scoreMap[diff]`

### 7.2 Điểm giao tiếp (`communicationScore`)
- `round(pair(expression)*0.6 + pair(personality)*0.4)`

### 7.3 Điểm tổng (`overallScore`)
- `round(core*0.3 + communication*0.25 + soul*0.3 + personality*0.15)`

### 7.4 Life Path của profile so sánh
- `CompatibilityBloc` lưu `lifePathNumber` của đối tượng compare bằng:
  - `NumerologyHelper.getLifePathNumber(birthDate)`

## 8. Lưu ý triển khai

1. Toàn bộ phép tính theo `DateTime.now()` local timezone trên thiết bị trừ khi có `nowProvider`.
2. `TodayPersonalContent` hiện vẫn có một số value UI tĩnh; nếu muốn đồng bộ 100% logic với snapshot time-life thì cần bind trực tiếp `personal_day/month/year` từ `MainSessionState.timeLifeByProfileId`.
3. Công thức trong tài liệu này phản ánh đúng code hiện tại; nếu sửa helper/bloc thì cần update tài liệu đồng thời.
