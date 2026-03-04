# Numverse Supabase Edge Function Spec

## Mục đích

Tài liệu này chốt spec cho các `Supabase Edge Functions` và flow `generate/cache` của `Numverse`, dựa trên:
- [NUMVERSE_DATA_MODEL.md](/Users/uranidev/Documents/Numverse/NUMVERSE_DATA_MODEL.md)
- [PROMPT_ARCHITECTURE.md](/Users/uranidev/Documents/Numverse/PROMPT_ARCHITECTURE.md)
- [NUMVERSE_USER_FLOW_UX_LOGIC.md](/Users/uranidev/Documents/Numverse/NUMVERSE_USER_FLOW_UX_LOGIC.md)

Mục tiêu:
- làm blueprint để bước sau có thể implement bằng `Supabase MCP`
- chốt rõ `cache hit / cache miss`
- chốt rõ `reads`, `writes`, `prompt lookup`, `Gemini call`, `error handling`

## 1. Runtime Assumption

- Tất cả function chạy trên `Supabase Edge Functions`
- Dùng `service role` để đọc/ghi các bảng hệ thống và bypass RLS khi cần
- Request từ client vẫn phải kèm `user JWT`
- Mọi function public đều phải verify `auth.uid()`
- Model provider hiện tại: `Gemini`
- Prompt source of truth: `public.prompt_templates`

## 2. Folder Structure Đề xuất

```text
supabase/functions/
  _shared/
    auth.ts
    db.ts
    prompts.ts
    gemini.ts
    cache.ts
    numerology.ts
    response.ts
  recalculate-numerology-profile/
  generate-snapshot-narrative/
  generate-daily-reading/
  generate-monthly-reading/
  generate-yearly-reading/
  generate-active-phase-reading/
  generate-compatibility-report/
  send-numai-message/
```

## 3. Shared Helper Contracts

### 3.1. `requireUser()`

Mục đích:
- validate JWT từ request
- trả ra `user_id`

Fail:
- `401 unauthorized`

### 3.2. `loadPrimaryProfile(user_id)`

Mục đích:
- lấy hồ sơ chính đang active

Fail:
- `404 primary_profile_not_found`

### 3.3. `resolveActivePrompt(prompt_key, locale)`

Mục đích:
- query `public.prompt_templates`
- lấy đúng bản `status = active`

Input:
- `prompt_key`
- `locale`

Fail:
- `404 prompt_not_found`
- `409 multiple_active_prompts` nếu có hơn 1 bản active

### 3.4. `createGenerationRun()`

Mục đích:
- insert record `queued` hoặc `running` vào `public.ai_generation_runs`

Field tối thiểu:
- `owner_user_id`
- `generation_kind`
- `prompt_template_id`
- `prompt_key`
- `provider`
- `model_name`
- `prompt_version`
- `status`
- `input_context_json`
- `started_at`

### 3.5. `completeGenerationRun()`

Mục đích:
- cập nhật `status = succeeded | failed`
- lưu `output_json`, `raw_text_output`, `error_text`, `latency_ms`, `completed_at`

### 3.6. `callGeminiJson()`

Mục đích:
- render prompt
- gọi Gemini
- validate JSON output theo `output_schema_json`

Input:
- `prompt_template`
- `context_json`

Output:
- `parsed_output`
- `raw_text_output`
- `latency_ms`

Fail:
- `provider_error`
- `invalid_json_output`
- `schema_validation_failed`

### 3.7. `computeLocalDateContext(profile, nowUtc)`

Mục đích:
- resolve timezone của profile
- tính:
  - `local_date`
  - `local_year`
  - `local_month`

## 4. Cache Strategy Tổng quát

### 4.1. `Life-based`

Cache key:
- `snapshot_id`
- `prompt_version`

Artifact:
- `public.numerology_snapshot_narratives`

### 4.2. `Daily preview`

Cache key:
- `profile_id`
- `local_date`
- `engine_version`

Artifact:
- `public.daily_readings`

### 4.3. `Monthly detail`

Cache key:
- `profile_id`
- `local_year`
- `local_month`
- `engine_version`

Artifact:
- `public.monthly_readings`

### 4.4. `Yearly detail`

Cache key:
- `profile_id`
- `local_year`
- `engine_version`

Artifact:
- `public.yearly_readings`

### 4.5. `Active phase detail`

Cache key:
- `profile_id`
- `phase_key`
- `engine_version`

Artifact:
- `public.active_phase_readings`

### 4.6. `Compatibility`

Cache key:
- `owner_user_id`
- `primary_profile_id`
- `target_profile_id`
- `engine_version`

Artifact:
- `public.compatibility_reports`

## 5. Response Envelope Đề xuất

Mọi function generate/cache nên trả theo envelope thống nhất:

```json
{
  "ok": true,
  "cache_status": "hit",
  "data": {},
  "meta": {
    "prompt_key": "daily_reading_narrative",
    "prompt_version": "v1",
    "engine_version": "v1"
  }
}
```

`cache_status`:
- `hit`
- `miss_generated`
- `miss_in_progress`

## 6. Function `recalculate-numerology-profile`

### Mục tiêu

- normalize input hồ sơ
- tính deterministic facts
- tạo `numerology_snapshot` mới
- invalidate cache phụ thuộc

### Trigger

- user tạo hồ sơ
- user sửa `họ tên` hoặc `ngày sinh`
- admin/manual refresh

### Input

```json
{
  "profile_id": "uuid"
}
```

### Reads

- `public.numerology_profiles`

### Writes

- `public.numerology_snapshots`
- invalidate old `is_current`

### Invalidate

- `public.numerology_snapshot_narratives`
- `public.daily_readings`
- `public.monthly_readings`
- `public.yearly_readings`
- `public.active_phase_readings`
- `public.compatibility_reports`

### Success response

```json
{
  "ok": true,
  "data": {
    "snapshot_id": "uuid",
    "profile_id": "uuid"
  }
}
```

## 7. Function `generate-snapshot-narrative`

### Mục tiêu

- generate narrative `life-based` từ snapshot deterministic

### Input

```json
{
  "snapshot_id": "uuid",
  "locale": "vi-VN",
  "force_regenerate": false
}
```

### Reads

- `public.numerology_snapshots`
- `public.numerology_profiles`
- `public.prompt_templates`

### Cache lookup

1. tìm snapshot hiện hành
2. tìm narrative `is_current = true` cho snapshot đó
3. nếu đã có và `force_regenerate = false` -> `cache_status = hit`

### Cache miss path

1. load prompt `life_snapshot_narrative`
2. build context
3. insert `ai_generation_run`
4. gọi Gemini
5. validate JSON
6. set old narrative `is_current = false`
7. insert narrative mới
8. complete generation run

### Writes

- `public.ai_generation_runs`
- `public.numerology_snapshot_narratives`

## 8. Function `generate-daily-reading`

### Mục tiêu

- tạo hoặc lấy `daily preview cache` cho tab `Hôm nay`

### Input

```json
{
  "profile_id": "uuid",
  "local_date": "2026-03-04",
  "locale": "vi-VN",
  "force_regenerate": false
}
```

`Note`:
- nếu `local_date` không truyền lên, function tự derive từ timezone của profile

### Reads

- `public.numerology_profiles`
- `public.numerology_snapshots`
- `public.numerology_snapshot_narratives`
- `public.daily_readings`
- `public.prompt_templates`

### Cache key

- `profile_id + local_date + engine_version`

### Cache hit path

1. query `daily_readings`
2. nếu có record hợp lệ -> trả về ngay

### Cache miss path

1. derive `personal_year`, `personal_month`, `personal_day`
2. derive `active_peak_number`, `active_challenge_number`
3. load prompt `daily_reading_narrative`
4. build context với `compact_summary`
5. insert `ai_generation_run`
6. gọi Gemini
7. validate output
8. insert `daily_readings`
9. nếu race condition xảy ra do unique key:
   - re-query record vừa được tạo
   - trả về `cache_status = hit`

### Writes

- `public.ai_generation_runs`
- `public.daily_readings`

### Output data

- full record `daily_readings`

## 9. Function `generate-monthly-reading`

### Mục tiêu

- tạo hoặc lấy `detail cache` cho màn `Chi tiết tháng này`

### Input

```json
{
  "profile_id": "uuid",
  "local_year": 2026,
  "local_month": 3,
  "locale": "vi-VN",
  "force_regenerate": false
}
```

### Reads

- `public.numerology_profiles`
- `public.numerology_snapshots`
- `public.numerology_snapshot_narratives`
- `public.monthly_readings`
- `public.prompt_templates`

### Cache key

- `profile_id + local_year + local_month + engine_version`

### Cache hit path

1. query `monthly_readings`
2. nếu có record hợp lệ -> trả về ngay

### Cache miss path

1. derive `personal_year`, `personal_month`
2. load prompt `monthly_reading_narrative`
3. build context
4. insert `ai_generation_run`
5. gọi Gemini
6. validate output
7. insert `monthly_readings`
8. xử lý race condition bằng unique key + re-query

### Writes

- `public.ai_generation_runs`
- `public.monthly_readings`

## 10. Function `generate-yearly-reading`

### Mục tiêu

- tạo hoặc lấy `detail cache` cho màn `Chi tiết năm nay`

### Input

```json
{
  "profile_id": "uuid",
  "local_year": 2026,
  "locale": "vi-VN",
  "force_regenerate": false
}
```

### Reads

- `public.numerology_profiles`
- `public.numerology_snapshots`
- `public.numerology_snapshot_narratives`
- `public.yearly_readings`
- `public.prompt_templates`

### Cache key

- `profile_id + local_year + engine_version`

### Cache miss path

1. derive `personal_year`
2. load prompt `yearly_reading_narrative`
3. build context
4. insert `ai_generation_run`
5. gọi Gemini
6. validate output
7. insert `yearly_readings`

### Writes

- `public.ai_generation_runs`
- `public.yearly_readings`

## 11. Function `generate-active-phase-reading`

### Mục tiêu

- tạo hoặc lấy `detail cache` cho màn `Chi tiết giai đoạn active`

### Input

```json
{
  "profile_id": "uuid",
  "phase_key": "optional-string",
  "locale": "vi-VN",
  "force_regenerate": false
}
```

`Note`:
- nếu `phase_key` không truyền lên, function tự derive từ deterministic engine

### Reads

- `public.numerology_profiles`
- `public.numerology_snapshots`
- `public.numerology_snapshot_narratives`
- `public.active_phase_readings`
- `public.prompt_templates`

### Cache key

- `profile_id + phase_key + engine_version`

### Cache miss path

1. derive current `phase_key`
2. derive `phase_start_date`, `phase_end_date`
3. derive `active_peak_number`, `active_challenge_number`
4. load prompt `active_phase_narrative`
5. build context
6. insert `ai_generation_run`
7. gọi Gemini
8. validate output
9. insert `active_phase_readings`

### Writes

- `public.ai_generation_runs`
- `public.active_phase_readings`

## 12. Function `generate-compatibility-report`

### Mục tiêu

- tạo hoặc lấy report tương hợp theo pair cache

### Input

```json
{
  "primary_profile_id": "uuid",
  "target_profile_id": "uuid",
  "locale": "vi-VN",
  "force_regenerate": false
}
```

### Reads

- `public.numerology_profiles`
- `public.numerology_snapshots`
- `public.numerology_snapshot_narratives`
- `public.compatibility_reports`
- `public.prompt_templates`

### Cache key

- `owner_user_id + primary_profile_id + target_profile_id + engine_version`

### Cache miss path

1. tính `compatibility_structure_json` và `score` bằng code nếu công thức đã có
2. load prompt `compatibility_narrative`
3. build context
4. insert `ai_generation_run`
5. gọi Gemini
6. validate output
7. insert `compatibility_reports`

### Writes

- `public.ai_generation_runs`
- `public.compatibility_reports`

## 13. Function `send-numai-message`

### Mục tiêu

- xử lý 1 lượt chat trong `NumAI`
- trừ `Soul Point` nếu user là free
- ghi message user và assistant

### Input

```json
{
  "thread_id": "uuid",
  "message_text": "string"
}
```

### Reads

- `public.ai_threads`
- `public.ai_messages`
- `public.numerology_profiles`
- `public.numerology_snapshots`
- `public.soul_point_wallets`
- `public.subscriptions`
- `public.prompt_templates`

### Context build MVP

- `thread_summary`
- `recent_messages` tối đa 20
- `active_profile`
- `snapshot_facts`
- `user_question`
- `context_type`

### Free/PRO gating

1. check subscription
2. nếu `PRO` -> gửi trực tiếp
3. nếu `Free`
   - check point
   - nếu đủ -> debit
   - nếu thiếu -> trả `402 not_enough_soul_points`

### Writes

- `public.soul_point_ledger`
- `public.soul_point_wallets`
- `public.ai_messages` cho user
- `public.ai_generation_runs`
- `public.ai_messages` cho assistant
- `public.ai_threads.last_message_at`
- `public.ai_threads.thread_summary`

### Output data

```json
{
  "ok": true,
  "data": {
    "thread_id": "uuid",
    "assistant_message_id": "uuid",
    "answer": "string"
  }
}
```

## 14. Race Condition Strategy

### 14.1. Generate functions

Với mọi cache artifact:
- query trước
- nếu miss -> generate
- insert theo unique key
- nếu conflict -> re-query và trả `hit`

### 14.2. Soul Point debit

Phải transactional:
1. lock wallet
2. verify balance
3. insert ledger
4. update wallet

Không được làm theo kiểu:
- đọc số dư ở app
- trừ số dư ở client

## 15. Error Model Đề xuất

Mọi function nên trả:

```json
{
  "ok": false,
  "error": {
    "code": "prompt_not_found",
    "message": "Active prompt template was not found."
  }
}
```

`code` chuẩn nên có:
- `unauthorized`
- `forbidden`
- `primary_profile_not_found`
- `profile_not_found`
- `snapshot_not_found`
- `prompt_not_found`
- `multiple_active_prompts`
- `not_enough_soul_points`
- `provider_error`
- `invalid_json_output`
- `schema_validation_failed`
- `cache_insert_conflict`
- `internal_error`

## 16. Implementation Order Đề xuất

1. `recalculate-numerology-profile`
2. `generate-snapshot-narrative`
3. `generate-daily-reading`
4. `generate-monthly-reading`
5. `generate-yearly-reading`
6. `generate-active-phase-reading`
7. `generate-compatibility-report`
8. `send-numai-message`

## 17. Chuẩn bị cho Supabase MCP Step Sau

Khi chuyển sang bước implement bằng MCP, tôi sẽ cần:
- migration đã có trong `supabase/migrations`
- seed prompt trong `supabase/seeds`
- schema validator choice:
  - `zod`
  - hoặc JSON Schema validator
- quyết định naming thật của các function path
- quyết định `engine_version` ban đầu
