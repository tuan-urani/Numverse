# Numverse Data Model

## Mục đích

Tài liệu này định nghĩa `data model` mới cho `Numverse` theo hướng `Supabase-first`, dựa trên:
- [NUMVERSE_PRODUCT_SUMMARY.md](/Users/uranidev/Documents/Numverse/NUMVERSE_PRODUCT_SUMMARY.md)
- [NUMVERSE_MOBILE_WIREFRAMES_LOFI.md](/Users/uranidev/Documents/Numverse/NUMVERSE_MOBILE_WIREFRAMES_LOFI.md)
- [NUMVERSE_USER_FLOW_UX_LOGIC.md](/Users/uranidev/Documents/Numverse/NUMVERSE_USER_FLOW_UX_LOGIC.md)

Mục tiêu:
- bám đúng các tab và flow đã chốt
- phù hợp với `Supabase Auth + Postgres + RLS + Edge Functions`
- phân tách rõ `source data`, `derived data`, `time-based data`, `Soul Point`, `NumAI`

## 1. Nguyên tắc thiết kế cho Supabase

### 1.1. Dùng `auth.users` làm gốc danh tính

- Không tạo bảng `users` riêng làm source of truth cho auth.
- Mọi bảng nghiệp vụ sẽ tham chiếu tới `auth.users.id`.
- Dữ liệu mở rộng của user được đặt trong `public.user_profiles`.

### 1.2. Dùng `public` cho dữ liệu ứng dụng

Các bảng ứng dụng nên nằm trong schema `public`:
- dễ dùng với Supabase client
- dễ áp `RLS`
- dễ query từ mobile app và Edge Functions

### 1.3. Ưu tiên `owner_user_id` trên các bảng nghiệp vụ

Thay vì luôn suy ra owner qua nhiều tầng relation, nên lưu trực tiếp:
- `owner_user_id uuid not null references auth.users(id)`

Lợi ích:
- RLS đơn giản hơn
- query nhanh hơn
- dễ audit dữ liệu theo user

### 1.4. Dùng `jsonb` cho dữ liệu numerology đã tính

Với `Luận giải`, `Hôm nay`, `Tương hợp`, không nên chuẩn hóa quá mức ngay từ đầu.

Nên:
- giữ dữ liệu nguồn ở dạng cột rõ ràng
- giữ dữ liệu diễn giải / tính toán ở `jsonb`

Lý do:
- công thức numerology và format content có thể thay đổi
- MVP cần linh hoạt
- Postgres trên Supabase hỗ trợ `jsonb` tốt

### 1.5. Tách dữ liệu đọc và dữ liệu tính toán

- `numerology_profiles`: dữ liệu người dùng nhập
- `numerology_snapshots`: kết quả `life-based`
- `daily_readings`: kết quả `time-based`
- `compatibility_reports`: kết quả tương hợp
- `ai_threads`, `ai_messages`: lịch sử chat

### 1.6. Tách quyền truy cập khỏi dữ liệu nội dung

Nội dung có thể được tính sẵn nhưng quyền hiển thị phụ thuộc vào:
- `subscriptions`
- `feature_unlocks`
- `soul_point_wallets`
- `soul_point_ledger`

## 2. Supabase Stack Assumption

Data model này giả định:
- `Supabase Auth` cho đăng nhập
- `Postgres` là database chính
- `Row Level Security` bật cho toàn bộ bảng `public`
- `Edge Functions` dùng cho:
  - tính numerology
  - generate `daily_readings`
  - generate `compatibility_reports`
  - gọi model cho `NumAI`
  - verify billing / sync entitlement nếu cần

## 3. Naming Convention

### 3.1. Kiểu dữ liệu

- `uuid` cho primary key
- `timestamptz` cho tất cả timestamp
- `date` cho ngày sinh và ngày local
- `jsonb` cho derived content
- `text` cho string chính

### 3.2. Cột chuẩn

Hầu hết các bảng nên có:
- `id uuid primary key default gen_random_uuid()`
- `owner_user_id uuid not null references auth.users(id) on delete cascade`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Riêng bảng one-to-one với `auth.users` có thể dùng `id` chính là `auth.users.id`.

## 4. Enum đề xuất

Các enum này nên được tạo ở Postgres để tránh string rời rạc.

### 4.1. `profile_kind`

- `self`
- `other`

### 4.2. `relation_kind`

- `self`
- `lover`
- `spouse`
- `friend`
- `mother`
- `father`
- `child`
- `sibling`
- `coworker`
- `other`

### 4.3. `subscription_status`

- `trialing`
- `active`
- `grace_period`
- `canceled`
- `expired`

### 4.4. `feature_code`

- `today_detail`
- `month_detail`
- `year_detail`
- `active_phase_detail`
- `numai_message`

### 4.5. `unlock_source`

- `subscription`
- `soul_point`
- `admin`

### 4.6. `ledger_direction`

- `credit`
- `debit`

### 4.7. `ledger_source_type`

- `daily_checkin`
- `streak_bonus`
- `ad_reward`
- `today_unlock`
- `numai_message`
- `manual_adjustment`

### 4.8. `ai_context_type`

- `general`
- `today`
- `reading`
- `compatibility`

## 5. ER Overview

```mermaid
erDiagram
    AUTH_USERS ||--|| USER_PROFILES : has
    AUTH_USERS ||--o{ SUBSCRIPTIONS : owns
    AUTH_USERS ||--|| SOUL_POINT_WALLETS : has
    AUTH_USERS ||--o{ SOUL_POINT_LEDGER : records
    AUTH_USERS ||--o{ DAILY_CHECKINS : has
    AUTH_USERS ||--o{ AD_REWARD_EVENTS : has

    AUTH_USERS ||--o{ NUMEROLOGY_PROFILES : owns
    NUMEROLOGY_PROFILES ||--o{ NUMEROLOGY_SNAPSHOTS : has
    NUMEROLOGY_PROFILES ||--o{ DAILY_READINGS : has
    NUMEROLOGY_PROFILES ||--o{ FEATURE_UNLOCKS : applies_to

    AUTH_USERS ||--o{ COMPATIBILITY_REPORTS : requests
    NUMEROLOGY_PROFILES ||--o{ COMPATIBILITY_REPORTS : primary_profile
    NUMEROLOGY_PROFILES ||--o{ COMPATIBILITY_REPORTS : target_profile

    AUTH_USERS ||--o{ AI_THREADS : owns
    AI_THREADS ||--o{ AI_MESSAGES : contains
    NUMEROLOGY_PROFILES ||--o{ AI_THREADS : scoped_to
```

## 6. Tables

## 6.1. `public.user_profiles`

Mục đích:
- dữ liệu app-level của user
- không chứa numerology data

Quan hệ:
- one-to-one với `auth.users`

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK, FK -> `auth.users.id` |
| `display_name` | `text` | no | Tên hiển thị |
| `locale` | `text` | yes | Default `vi-VN` |
| `timezone` | `text` | yes | Default `Asia/Ho_Chi_Minh` |
| `onboarding_completed` | `boolean` | yes | Default `false` |
| `last_active_at` | `timestamptz` | no |  |
| `created_at` | `timestamptz` | yes | Default `now()` |
| `updated_at` | `timestamptz` | yes | Default `now()` |

`RLS`:
- user chỉ `select/update` record có `id = auth.uid()`

## 6.2. `public.user_settings`

Mục đích:
- lưu cài đặt ứng dụng

| Column | Type | Required | Notes |
|---|---|---:|---|
| `user_id` | `uuid` | yes | PK, FK -> `auth.users.id` |
| `language` | `text` | yes | Default `vi` |
| `timezone` | `text` | yes | Có thể mirror từ `user_profiles` |
| `daily_notification_enabled` | `boolean` | yes | Default `true` |
| `daily_notification_time` | `time` | no |  |
| `marketing_opt_in` | `boolean` | yes | Default `false` |
| `analytics_opt_in` | `boolean` | yes | Default `true` |
| `created_at` | `timestamptz` | yes |  |
| `updated_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ truy cập record của chính mình

## 6.3. `public.subscriptions`

Mục đích:
- lưu quyền `VIP PRO`

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `provider` | `text` | yes | `app_store`, `google_play` |
| `product_code` | `text` | yes | SKU |
| `status` | `subscription_status` | yes |  |
| `started_at` | `timestamptz` | yes |  |
| `expires_at` | `timestamptz` | no |  |
| `auto_renew` | `boolean` | yes |  |
| `provider_customer_id` | `text` | no |  |
| `provider_subscription_id` | `text` | no |  |
| `entitlements_json` | `jsonb` | no | Ví dụ `{"today_full": true, "numai_unmetered": true}` |
| `last_verified_at` | `timestamptz` | no |  |
| `created_at` | `timestamptz` | yes |  |
| `updated_at` | `timestamptz` | yes |  |

`RLS`:
- user được `select` subscription của chính mình
- insert/update chủ yếu qua `service_role` hoặc `Edge Function`

## 6.4. `public.numerology_profiles`

Mục đích:
- hồ sơ dùng để luận giải
- gồm hồ sơ bản thân và hồ sơ người khác

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `profile_kind` | `profile_kind` | yes | `self`, `other` |
| `relation_kind` | `relation_kind` | yes |  |
| `display_name` | `text` | yes | Tên ngắn trên UI |
| `full_name_for_reading` | `text` | yes | Họ tên dùng để tính numerology |
| `birth_date` | `date` | yes |  |
| `gender` | `text` | no | Nếu cần dùng trong content |
| `is_primary` | `boolean` | yes | Chỉ 1 hồ sơ chính |
| `notes` | `text` | no | Ghi chú nội bộ |
| `archived_at` | `timestamptz` | no | Soft delete |
| `created_at` | `timestamptz` | yes |  |
| `updated_at` | `timestamptz` | yes |  |

`Constraints`:
- partial unique index cho `owner_user_id` khi `is_primary = true and archived_at is null`

`RLS`:
- user chỉ truy cập hồ sơ của chính mình

## 6.5. `public.numerology_snapshots`

Mục đích:
- lưu kết quả `life-based`
- snapshot theo version của engine
- tránh phải tính lại mỗi lần mở app

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `numerology_profile_id` | `uuid` | yes | FK -> `public.numerology_profiles.id` |
| `engine_version` | `text` | yes | Version calculator |
| `source_hash` | `text` | yes | Hash từ input normalized |
| `is_current` | `boolean` | yes | Snapshot active |
| `raw_input_json` | `jsonb` | yes | Input normalized |
| `core_numbers_json` | `jsonb` | yes | Số chủ đạo, biểu đạt, linh hồn, nhân cách |
| `birth_matrix_json` | `jsonb` | yes | Biểu đồ ngày sinh, số mạnh/yếu/thiếu |
| `matrix_aspects_json` | `jsonb` | yes | Trục và mũi tên |
| `life_path_json` | `jsonb` | yes | 4 đỉnh cao, 4 thử thách |
| `persona_json` | `jsonb` | yes | Chân dung cá nhân |
| `calculated_at` | `timestamptz` | yes |  |
| `created_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ đọc snapshot thuộc `owner_user_id = auth.uid()`
- insert/update qua `Edge Function` hoặc `service_role`

`Recommended JSON structure`:

```json
{
  "core_numbers": {
    "life_path": { "value": 7, "title": "So chu dao", "summary": "..." },
    "expression": { "value": 3, "title": "So bieu dat", "summary": "..." },
    "soul_urge": { "value": 2, "title": "So linh hon", "summary": "..." },
    "personality": { "value": 1, "title": "So nhan cach", "summary": "..." }
  },
  "birth_matrix": {
    "grid": [[1, 4, 7], [2, null, 8], [3, null, 9]],
    "strong_numbers": [1, 7],
    "weak_numbers": [2, 8],
    "missing_numbers": [5, 6]
  },
  "matrix_aspects": {
    "axes": [],
    "arrows": []
  },
  "life_path": {
    "peaks": [],
    "challenges": []
  },
  "persona": {
    "overview": "...",
    "strengths": [],
    "balance_points": [],
    "communication_style": "...",
    "love_style": "...",
    "career_fit": "..."
  }
}
```

## 6.6. `public.daily_readings`

Mục đích:
- lưu dữ liệu cho tab `Hôm nay`
- phục vụ free layer và deep layer

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `numerology_profile_id` | `uuid` | yes | FK -> `public.numerology_profiles.id` |
| `local_date` | `date` | yes | Ngày theo timezone user |
| `timezone` | `text` | yes | Dùng để trace |
| `engine_version` | `text` | yes |  |
| `personal_year` | `smallint` | yes |  |
| `personal_month` | `smallint` | yes |  |
| `personal_day` | `smallint` | yes |  |
| `energy_score` | `smallint` | no | Ví dụ `1..10` |
| `daily_rhythm` | `text` | no | Ví dụ `Tinh - Quan sat` |
| `daily_insight_short` | `text` | yes | Free layer |
| `daily_insight_full` | `text` | no | PRO layer |
| `action_do_json` | `jsonb` | yes | Nên làm |
| `action_avoid_json` | `jsonb` | yes | Nên tránh |
| `month_context_json` | `jsonb` | yes | Tháng này |
| `year_context_json` | `jsonb` | yes | Năm nay |
| `active_phase_json` | `jsonb` | no | Đỉnh cao active + thử thách active |
| `generated_at` | `timestamptz` | yes |  |
| `created_at` | `timestamptz` | yes |  |

`Constraints`:
- unique index trên `(numerology_profile_id, local_date, engine_version)`

`RLS`:
- user chỉ đọc record của chính mình
- ghi qua `Edge Function`

## 6.7. `public.feature_unlocks`

Mục đích:
- lưu các lần mở khóa lẻ bằng `Soul Point`
- áp dụng cho deep content trong `Hôm nay`
- có thể dùng cho `NumAI` nếu sau này muốn mở theo batch

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `numerology_profile_id` | `uuid` | no | FK -> `public.numerology_profiles.id` |
| `feature_code` | `feature_code` | yes |  |
| `scope_key` | `text` | yes | Ví dụ `2026-03-04`, `2026-03`, `2026` |
| `unlock_source` | `unlock_source` | yes |  |
| `soul_point_cost` | `integer` | no |  |
| `starts_at` | `timestamptz` | yes |  |
| `expires_at` | `timestamptz` | yes |  |
| `metadata_json` | `jsonb` | no |  |
| `created_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ đọc record của chính mình
- insert qua function xử lý point

## 6.8. `public.soul_point_wallets`

Mục đích:
- cache số dư hiện tại để đọc nhanh

| Column | Type | Required | Notes |
|---|---|---:|---|
| `user_id` | `uuid` | yes | PK, FK -> `auth.users.id` |
| `balance` | `integer` | yes | Default `0` |
| `lifetime_earned` | `integer` | yes | Default `0` |
| `lifetime_spent` | `integer` | yes | Default `0` |
| `created_at` | `timestamptz` | yes |  |
| `updated_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ đọc wallet của chính mình
- update qua RPC / transaction server-side

## 6.9. `public.soul_point_ledger`

Mục đích:
- sổ cái bất biến cho toàn bộ biến động `Soul Point`

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `direction` | `ledger_direction` | yes | `credit` hoặc `debit` |
| `amount` | `integer` | yes | Luôn dương |
| `source_type` | `ledger_source_type` | yes |  |
| `source_ref_id` | `uuid` | no | Event gốc |
| `balance_after` | `integer` | yes | Snapshot sau giao dịch |
| `metadata_json` | `jsonb` | no | Ví dụ `{"feature_code":"today_detail"}` |
| `created_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ đọc ledger của chính mình
- insert bằng RPC hoặc Edge Function

## 6.10. `public.daily_checkins`

Mục đích:
- track điểm danh hằng ngày
- cấp point
- tính streak

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `local_date` | `date` | yes | Theo timezone user |
| `streak_count` | `integer` | yes |  |
| `reward_amount` | `integer` | yes |  |
| `created_at` | `timestamptz` | yes |  |

`Constraints`:
- unique index `(owner_user_id, local_date)`

## 6.11. `public.ad_reward_events`

Mục đích:
- log lượt quảng cáo đổi point

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `ad_network` | `text` | yes |  |
| `placement_code` | `text` | yes |  |
| `reward_amount` | `integer` | yes |  |
| `status` | `text` | yes | `pending`, `granted`, `rejected` |
| `metadata_json` | `jsonb` | no |  |
| `created_at` | `timestamptz` | yes |  |

## 6.12. `public.compatibility_reports`

Mục đích:
- lưu dữ liệu tab `Tương hợp`

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `primary_profile_id` | `uuid` | yes | FK -> `public.numerology_profiles.id` |
| `target_profile_id` | `uuid` | yes | FK -> `public.numerology_profiles.id` |
| `engine_version` | `text` | yes |  |
| `score` | `smallint` | yes | `0..100` |
| `summary` | `text` | yes | Nhận định chung |
| `strengths_json` | `jsonb` | yes | Điểm hợp |
| `tensions_json` | `jsonb` | yes | Điểm xung đột |
| `guidance_json` | `jsonb` | yes | Gợi ý quan hệ |
| `calculated_at` | `timestamptz` | yes |  |
| `created_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ đọc report của chính mình

`Note`:
- report được cache theo cặp hồ sơ + engine version
- nên index `(owner_user_id, primary_profile_id, target_profile_id, engine_version)`

## 6.13. `public.ai_threads`

Mục đích:
- thread chat trong `NumAI`

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `primary_profile_id` | `uuid` | yes | FK -> `public.numerology_profiles.id` |
| `related_profile_id` | `uuid` | no | Dùng khi hỏi về tương hợp |
| `context_type` | `ai_context_type` | yes |  |
| `title` | `text` | no |  |
| `last_message_at` | `timestamptz` | no |  |
| `created_at` | `timestamptz` | yes |  |
| `updated_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ đọc / tạo thread của mình

## 6.14. `public.ai_messages`

Mục đích:
- lưu message trong chat `NumAI`

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `owner_user_id` | `uuid` | yes | FK -> `auth.users.id` |
| `thread_id` | `uuid` | yes | FK -> `public.ai_threads.id` |
| `sender_type` | `text` | yes | `user`, `assistant`, `system` |
| `message_text` | `text` | yes |  |
| `context_snapshot_id` | `uuid` | no | FK -> `public.numerology_snapshots.id` |
| `context_daily_reading_id` | `uuid` | no | FK -> `public.daily_readings.id` |
| `context_compatibility_report_id` | `uuid` | no | FK -> `public.compatibility_reports.id` |
| `soul_point_cost` | `integer` | yes | Default `0` |
| `metadata_json` | `jsonb` | no | Token usage, model info, moderation, prompt version |
| `created_at` | `timestamptz` | yes |  |

`RLS`:
- user chỉ đọc message trong thread của mình
- insert user message qua client hoặc function
- assistant message ghi qua Edge Function

## 6.15. `public.content_templates`

Mục đích:
- chứa template nội dung tĩnh / bán tĩnh cho numerology
- giúp `Luận giải` và `Hôm nay` ổn định hơn, ít phụ thuộc AI hơn

| Column | Type | Required | Notes |
|---|---|---:|---|
| `id` | `uuid` | yes | PK |
| `domain` | `text` | yes | `core_number`, `matrix_axis`, `personal_year`, ... |
| `template_key` | `text` | yes | Ví dụ `life_path_7` |
| `locale` | `text` | yes | `vi-VN` |
| `title` | `text` | yes |  |
| `summary_template` | `text` | yes |  |
| `body_template` | `text` | yes |  |
| `metadata_json` | `jsonb` | no | Tags, keywords |
| `created_at` | `timestamptz` | yes |  |
| `updated_at` | `timestamptz` | yes |  |

`RLS`:
- read-only cho authenticated users hoặc chỉ server-side tùy chiến lược

## 7. Mapping sang Tab / Feature

## 7.1. Tab `Luận giải`

Nguồn dữ liệu chính:
- `public.numerology_profiles`
- `public.numerology_snapshots`

Sections:
- `Chỉ số cốt lõi` -> `core_numbers_json`
- `Biểu đồ và ma trận` -> `birth_matrix_json`, `matrix_aspects_json`
- `Lộ trình cuộc đời` -> `life_path_json`
- `Chân dung cá nhân` -> `persona_json`

Access:
- `Free` xem full

## 7.2. Tab `Hôm nay`

Nguồn dữ liệu chính:
- `public.daily_readings`
- `public.feature_unlocks`
- `public.subscriptions`
- `public.soul_point_wallets`

Access:
- `Free`:
  - `daily_insight_short`
  - `energy_score`
  - preview `month_context_json`
  - preview `year_context_json`
  - preview `active_phase_json`
- `PRO`:
  - full `daily_insight_full`
  - full `action_do_json`
  - full `action_avoid_json`
  - full `month_context_json`
  - full `year_context_json`
  - full `active_phase_json`
- `Soul Point`:
  - tạo `feature_unlocks` theo scope

## 7.3. Tab `Tương hợp`

Nguồn dữ liệu chính:
- `public.numerology_profiles`
- `public.compatibility_reports`

Access:
- hiện tại data model hỗ trợ cả `free preview` và `PRO`

## 7.4. Tab `NumAI`

Nguồn dữ liệu chính:
- `public.ai_threads`
- `public.ai_messages`
- `public.numerology_snapshots`
- `public.daily_readings`
- `public.compatibility_reports`
- `public.soul_point_wallets`
- `public.soul_point_ledger`

Access:
- `Free`:
  - vào được tab
  - gửi từng message nếu đủ point
- `PRO`:
  - vào được tab
  - gửi message trực tiếp

## 7.5. Tab `Tôi`

Nguồn dữ liệu chính:
- `public.user_profiles`
- `public.user_settings`
- `public.numerology_profiles`
- `public.subscriptions`
- `public.soul_point_wallets`

## 8. Derived Data Logic

## 8.1. Khi tạo hoặc sửa `numerology_profile`

```text
profile insert/update
-> normalize input
-> generate source_hash
-> create new numerology_snapshot
-> set old snapshot is_current = false
-> invalidate compatibility_reports có liên quan
-> invalidate future daily_readings cache nếu cần
```

## 8.2. Khi user mở app và vào tab `Hôm nay`

```text
load primary profile
-> tìm daily_reading theo local_date hôm nay
-> nếu chưa có thì generate qua Edge Function
-> trả dữ liệu theo access level
```

## 8.3. Khi free user mở sâu `Hôm nay`

```text
check active subscription
-> nếu PRO thì cho xem
-> nếu không PRO
   -> check feature_unlocks còn hạn
   -> nếu có thì cho xem
   -> nếu chưa có thì trừ Soul Point và tạo feature_unlock
```

## 8.4. Khi free user gửi chat trong `NumAI`

```text
check wallet balance
-> nếu đủ point
   -> debit soul_point_ledger
   -> update soul_point_wallets
   -> create ai_messages sender=user
   -> call model qua Edge Function
   -> create ai_messages sender=assistant
-> nếu không đủ point
   -> trả trạng thái thiếu point
```

## 9. RLS Policy Direction

Hướng chung:
- mọi bảng `public` bật `RLS`
- mọi bảng có `owner_user_id` dùng policy `owner_user_id = auth.uid()`
- bảng one-to-one với auth dùng `id = auth.uid()` hoặc `user_id = auth.uid()`

### 9.1. Chính sách đơn giản đề xuất

`user_profiles`
- select: `id = auth.uid()`
- update: `id = auth.uid()`

`user_settings`
- select: `user_id = auth.uid()`
- update: `user_id = auth.uid()`

Các bảng có `owner_user_id`
- select: `owner_user_id = auth.uid()`
- insert: `owner_user_id = auth.uid()`
- update: `owner_user_id = auth.uid()`
- delete: `owner_user_id = auth.uid()`

`subscriptions`
- select cho user
- insert/update chủ yếu qua `service_role`

`content_templates`
- select cho authenticated users hoặc chặn hoàn toàn ở client tùy triển khai

## 10. Indexes đề xuất

| Table | Index | Purpose |
|---|---|---|
| `numerology_profiles` | partial unique `(owner_user_id)` where `is_primary = true and archived_at is null` | 1 hồ sơ chính |
| `numerology_snapshots` | `(numerology_profile_id, is_current)` | lấy snapshot hiện hành |
| `numerology_snapshots` | `(owner_user_id, numerology_profile_id, created_at desc)` | history |
| `daily_readings` | unique `(numerology_profile_id, local_date, engine_version)` | cache hôm nay |
| `feature_unlocks` | `(owner_user_id, numerology_profile_id, feature_code, scope_key)` | check unlock nhanh |
| `soul_point_ledger` | `(owner_user_id, created_at desc)` | lịch sử point |
| `daily_checkins` | unique `(owner_user_id, local_date)` | chống check-in trùng |
| `compatibility_reports` | `(owner_user_id, primary_profile_id, target_profile_id, engine_version)` | cache tương hợp |
| `ai_threads` | `(owner_user_id, updated_at desc)` | danh sách thread |
| `ai_messages` | `(thread_id, created_at)` | render chat |

## 11. RPC / Edge Function Notes

Với Supabase, một số thao tác nên đi qua `RPC` hoặc `Edge Function` thay vì client insert trực tiếp:

- `claim_daily_checkin()`
- `unlock_feature_with_soul_point(feature_code, scope_key, profile_id)`
- `send_numai_message(thread_id, message_text)`
- `generate_daily_reading(profile_id, local_date)`
- `generate_compatibility_report(primary_profile_id, target_profile_id)`
- `recalculate_numerology_profile(profile_id)`

Lý do:
- đảm bảo transaction
- tránh race condition khi trừ point
- giấu prompt AI và business logic
- giảm rủi ro client bypass logic

## 12. MVP Scope

### Bảng bắt buộc

- `public.user_profiles`
- `public.user_settings`
- `public.subscriptions`
- `public.numerology_profiles`
- `public.numerology_snapshots`
- `public.daily_readings`
- `public.feature_unlocks`
- `public.soul_point_wallets`
- `public.soul_point_ledger`
- `public.daily_checkins`
- `public.compatibility_reports`
- `public.ai_threads`
- `public.ai_messages`

### Bảng có thể thêm sau

- `public.ad_reward_events`
- `public.content_templates`

## 13. Quyết định thực dụng cho MVP

1. Không cần chuẩn hóa từng chỉ số numerology thành bảng riêng.
2. Dùng `jsonb` cho toàn bộ phần diễn giải là đủ.
3. Dùng `Edge Functions` cho tất cả flow có `Soul Point` hoặc `AI`.
4. Dùng `RLS` đơn giản theo `owner_user_id`.
5. Xem `daily_readings` và `compatibility_reports` như cache có thể regenerate.

## 14. Open Questions

1. `Tương hợp` ở MVP là `free preview` hay `PRO`.
2. `NumAI` charge point theo `mỗi message` hay `mỗi lượt request`.
3. `Hôm nay` unlock bằng point sẽ hết hạn cuối ngày hay theo thời lượng.
4. Có cần lưu `soft delete` cho `ai_threads` và `ai_messages` hay không.
5. Có cần thêm bảng `billing_events` riêng để audit subscription sâu hơn hay không.
