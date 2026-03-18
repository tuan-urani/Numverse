create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'generation_kind'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.generation_kind as enum (
      'snapshot_narrative',
      'daily_reading_narrative',
      'monthly_reading_narrative',
      'yearly_reading_narrative',
      'active_phase_narrative',
      'compatibility_narrative',
      'numai_reply'
    );
  end if;
end
$$;

alter type public.generation_kind add value if not exists 'snapshot_narrative';
alter type public.generation_kind add value if not exists 'daily_reading_narrative';
alter type public.generation_kind add value if not exists 'monthly_reading_narrative';
alter type public.generation_kind add value if not exists 'yearly_reading_narrative';
alter type public.generation_kind add value if not exists 'active_phase_narrative';
alter type public.generation_kind add value if not exists 'compatibility_narrative';
alter type public.generation_kind add value if not exists 'numai_reply';

do $$
begin
  if not exists (
    select 1
    from pg_type
    where typname = 'generation_status'
      and typnamespace = 'public'::regnamespace
  ) then
    create type public.generation_status as enum (
      'queued',
      'running',
      'succeeded',
      'failed'
    );
  end if;
end
$$;

alter type public.generation_status add value if not exists 'queued';
alter type public.generation_status add value if not exists 'running';
alter type public.generation_status add value if not exists 'succeeded';
alter type public.generation_status add value if not exists 'failed';

create table if not exists public.numerology_snapshots (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  numerology_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  engine_version text not null,
  source_hash text not null,
  is_current boolean not null default true,
  raw_input_json jsonb not null,
  core_numbers_json jsonb not null,
  birth_matrix_json jsonb not null,
  matrix_aspects_json jsonb not null,
  life_cycles_json jsonb not null,
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table if not exists public.prompt_templates (
  id uuid primary key default gen_random_uuid(),
  prompt_key text not null,
  version text not null,
  locale text not null,
  status text not null check (status in ('draft', 'active', 'archived')),
  provider text not null,
  model_name text not null,
  temperature numeric(3,2),
  max_output_tokens integer,
  system_prompt text not null,
  task_prompt_template text not null,
  context_schema_json jsonb,
  output_schema_json jsonb,
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_generation_runs (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  generation_kind public.generation_kind not null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  prompt_key text not null,
  target_table text not null,
  target_id uuid,
  provider text not null,
  model_name text not null,
  prompt_version text not null,
  system_prompt_snapshot text,
  task_prompt_snapshot text,
  schema_version text,
  status public.generation_status not null,
  input_hash text,
  input_context_json jsonb not null default '{}'::jsonb,
  output_json jsonb,
  raw_text_output text,
  error_text text,
  latency_ms integer,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.ai_threads (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  primary_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  related_profile_id uuid references public.numerology_profiles(id) on delete set null,
  title text,
  thread_summary text,
  thread_summary_updated_at timestamptz,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  thread_id uuid not null references public.ai_threads(id) on delete cascade,
  sender_type text not null check (sender_type in ('user', 'assistant', 'system')),
  message_text text not null,
  context_snapshot_id uuid references public.numerology_snapshots(id) on delete set null,
  context_daily_reading_id uuid references public.daily_checkins(id) on delete set null,
  context_compatibility_report_id uuid references public.compatibility_history_items(id) on delete set null,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  soul_point_cost integer not null default 0 check (soul_point_cost >= 0),
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists numerology_snapshots_current_uidx
  on public.numerology_snapshots (numerology_profile_id)
  where is_current = true;

create index if not exists numerology_snapshots_profile_current_idx
  on public.numerology_snapshots (numerology_profile_id, is_current);

create index if not exists numerology_snapshots_owner_profile_created_idx
  on public.numerology_snapshots (owner_user_id, numerology_profile_id, created_at desc);

create unique index if not exists prompt_templates_prompt_key_locale_version_uidx
  on public.prompt_templates (prompt_key, locale, version);

create unique index if not exists prompt_templates_one_active_uidx
  on public.prompt_templates (prompt_key, locale)
  where status = 'active';

create index if not exists ai_generation_runs_owner_created_idx
  on public.ai_generation_runs (owner_user_id, created_at desc);

create index if not exists ai_generation_runs_target_idx
  on public.ai_generation_runs (target_table, target_id);

create index if not exists ai_generation_runs_prompt_template_created_idx
  on public.ai_generation_runs (prompt_template_id, created_at desc);

create index if not exists ai_threads_owner_updated_idx
  on public.ai_threads (owner_user_id, updated_at desc);

create index if not exists ai_messages_thread_created_idx
  on public.ai_messages (thread_id, created_at);

with ranked_threads as (
  select
    id,
    row_number() over (
      partition by owner_user_id, primary_profile_id
      order by updated_at desc nulls last, created_at desc nulls last, id desc
    ) as row_num
  from public.ai_threads
)
delete from public.ai_threads t
using ranked_threads r
where t.id = r.id
  and r.row_num > 1;

create unique index if not exists ai_threads_owner_primary_profile_uidx
  on public.ai_threads (owner_user_id, primary_profile_id);

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_prompt_templates_updated_at'
  ) then
    create trigger set_prompt_templates_updated_at
    before update on public.prompt_templates
    for each row execute function public.set_updated_at();
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'set_ai_threads_updated_at'
  ) then
    create trigger set_ai_threads_updated_at
    before update on public.ai_threads
    for each row execute function public.set_updated_at();
  end if;
end
$$;

create or replace function public.cleanup_ai_threads_on_profile_archive()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.archived_at is not null
     and (old.archived_at is null or old.archived_at <> new.archived_at) then
    delete from public.ai_threads
    where owner_user_id = new.owner_user_id
      and (primary_profile_id = new.id or related_profile_id = new.id);
  end if;

  return new;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'cleanup_ai_threads_on_profile_archive_trigger'
  ) then
    create trigger cleanup_ai_threads_on_profile_archive_trigger
    after update of archived_at on public.numerology_profiles
    for each row execute function public.cleanup_ai_threads_on_profile_archive();
  end if;
end
$$;

alter table if exists public.numerology_snapshots enable row level security;
alter table if exists public.prompt_templates enable row level security;
alter table if exists public.ai_generation_runs enable row level security;
alter table if exists public.ai_threads enable row level security;
alter table if exists public.ai_messages enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'numerology_snapshots'
      and policyname = 'numerology_snapshots_select_own'
  ) then
    create policy numerology_snapshots_select_own
      on public.numerology_snapshots
      for select
      to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'prompt_templates'
      and policyname = 'prompt_templates_no_client_access'
  ) then
    create policy prompt_templates_no_client_access
      on public.prompt_templates
      for all
      to authenticated, anon
      using (false)
      with check (false);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_generation_runs'
      and policyname = 'ai_generation_runs_select_own'
  ) then
    create policy ai_generation_runs_select_own
      on public.ai_generation_runs
      for select
      to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_threads'
      and policyname = 'ai_threads_select_own'
  ) then
    create policy ai_threads_select_own
      on public.ai_threads
      for select
      to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_threads'
      and policyname = 'ai_threads_insert_own'
  ) then
    create policy ai_threads_insert_own
      on public.ai_threads
      for insert
      to authenticated
      with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_threads'
      and policyname = 'ai_threads_update_own'
  ) then
    create policy ai_threads_update_own
      on public.ai_threads
      for update
      to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id)
      with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_threads'
      and policyname = 'ai_threads_delete_own'
  ) then
    create policy ai_threads_delete_own
      on public.ai_threads
      for delete
      to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_messages'
      and policyname = 'ai_messages_select_own'
  ) then
    create policy ai_messages_select_own
      on public.ai_messages
      for select
      to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'ai_messages'
      and policyname = 'ai_messages_insert_own'
  ) then
    create policy ai_messages_insert_own
      on public.ai_messages
      for insert
      to authenticated
      with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

update public.prompt_templates
set status = 'archived',
    updated_at = now()
where prompt_key = 'numai_chat_reply'
  and locale = 'vi-VN'
  and status = 'active'
  and version <> 'v1_points_memory';

insert into public.prompt_templates (
  prompt_key,
  version,
  locale,
  status,
  provider,
  model_name,
  temperature,
  max_output_tokens,
  system_prompt,
  task_prompt_template,
  context_schema_json,
  output_schema_json,
  notes
)
values (
  'numai_chat_reply',
  'v1_points_memory',
  'vi-VN',
  'active',
  'gemini',
  'gemini-1.5-flash',
  0.35,
  1200,
  'Bạn là NumAI, trợ lý thần số học cá nhân hóa theo profile người dùng. Trả lời rõ ràng, thực tế, không phán xét, không hứa hẹn cực đoan.',
  'Trả về JSON hợp lệ theo output schema.\n\nYêu cầu bắt buộc:\n1) Trường answer: trả lời ngắn gọn, có thể hành động, dựa trên active_profile + snapshot_facts + recent_messages.\n2) Trường suggestions: đúng 3 câu gợi ý tiếp theo, cụ thể theo ngữ cảnh người dùng hiện tại.\n3) referenced_sections: liệt kê các phần dữ liệu đã dùng, ví dụ core_numbers, matrix_aspects, life_cycles.\n\nKhông trả lời markdown, không bao ngoài bằng ```.',
  '{
    "type": "object",
    "required": ["thread_summary", "recent_messages", "active_profile", "snapshot_facts", "user_question"],
    "properties": {
      "thread_summary": {"type": "object"},
      "recent_messages": {"type": "array"},
      "active_profile": {"type": "object"},
      "snapshot_facts": {"type": "object"},
      "user_question": {"type": "string"}
    }
  }'::jsonb,
  '{
    "type": "object",
    "required": ["answer", "suggestions"],
    "properties": {
      "answer": {"type": "string"},
      "suggestions": {
        "type": "array",
        "minItems": 3,
        "maxItems": 3,
        "items": {"type": "string"}
      },
      "follow_up_suggestions": {
        "type": "array",
        "items": {"type": "string"}
      },
      "referenced_sections": {
        "type": "array",
        "items": {"type": "string"}
      }
    }
  }'::jsonb,
  'Point-only NumAI chat prompt with strict 3 follow-up suggestions.'
)
on conflict (prompt_key, locale, version)
do update set
  status = excluded.status,
  provider = excluded.provider,
  model_name = excluded.model_name,
  temperature = excluded.temperature,
  max_output_tokens = excluded.max_output_tokens,
  system_prompt = excluded.system_prompt,
  task_prompt_template = excluded.task_prompt_template,
  context_schema_json = excluded.context_schema_json,
  output_schema_json = excluded.output_schema_json,
  notes = excluded.notes,
  updated_at = now();
