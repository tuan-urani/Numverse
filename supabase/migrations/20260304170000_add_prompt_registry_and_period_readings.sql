-- Assumption:
-- Base schema already exists for:
-- public.numerology_profiles
-- public.numerology_snapshot_narratives
-- public.daily_readings
-- public.compatibility_reports
-- public.ai_generation_runs
-- public.ai_threads
-- public.ai_messages
-- public.feature_unlocks
-- public.generation_kind

create extension if not exists pgcrypto;

do $$
begin
  if exists (
    select 1
    from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where t.typname = 'generation_kind'
      and n.nspname = 'public'
  ) then
    if not exists (
      select 1
      from pg_enum e
      join pg_type t on t.oid = e.enumtypid
      join pg_namespace n on n.oid = t.typnamespace
      where t.typname = 'generation_kind'
        and n.nspname = 'public'
        and e.enumlabel = 'monthly_reading_narrative'
    ) then
      alter type public.generation_kind add value 'monthly_reading_narrative';
    end if;

    if not exists (
      select 1
      from pg_enum e
      join pg_type t on t.oid = e.enumtypid
      join pg_namespace n on n.oid = t.typnamespace
      where t.typname = 'generation_kind'
        and n.nspname = 'public'
        and e.enumlabel = 'yearly_reading_narrative'
    ) then
      alter type public.generation_kind add value 'yearly_reading_narrative';
    end if;

    if not exists (
      select 1
      from pg_enum e
      join pg_type t on t.oid = e.enumtypid
      join pg_namespace n on n.oid = t.typnamespace
      where t.typname = 'generation_kind'
        and n.nspname = 'public'
        and e.enumlabel = 'active_phase_narrative'
    ) then
      alter type public.generation_kind add value 'active_phase_narrative';
    end if;
  end if;
end
$$;

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

create unique index if not exists prompt_templates_prompt_key_locale_version_uidx
  on public.prompt_templates (prompt_key, locale, version);

create index if not exists prompt_templates_active_idx
  on public.prompt_templates (prompt_key, locale)
  where status = 'active';

alter table public.prompt_templates enable row level security;

create table if not exists public.monthly_readings (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  numerology_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  local_year smallint not null,
  local_month smallint not null check (local_month between 1 and 12),
  timezone text not null,
  engine_version text not null,
  personal_year smallint not null,
  personal_month smallint not null,
  headline text not null,
  summary_text text not null,
  focus_text text not null,
  opportunities_json jsonb not null,
  cautions_json jsonb not null,
  guidance_json jsonb not null,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  model_name text,
  prompt_version text,
  generated_at timestamptz not null,
  created_at timestamptz not null default now()
);

create unique index if not exists monthly_readings_profile_year_month_engine_uidx
  on public.monthly_readings (numerology_profile_id, local_year, local_month, engine_version);

create index if not exists monthly_readings_owner_created_idx
  on public.monthly_readings (owner_user_id, created_at desc);

alter table public.monthly_readings enable row level security;

create table if not exists public.yearly_readings (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  numerology_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  local_year smallint not null,
  timezone text not null,
  engine_version text not null,
  personal_year smallint not null,
  headline text not null,
  summary_text text not null,
  theme_text text not null,
  priorities_json jsonb not null,
  cautions_json jsonb not null,
  guidance_json jsonb not null,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  model_name text,
  prompt_version text,
  generated_at timestamptz not null,
  created_at timestamptz not null default now()
);

create unique index if not exists yearly_readings_profile_year_engine_uidx
  on public.yearly_readings (numerology_profile_id, local_year, engine_version);

create index if not exists yearly_readings_owner_created_idx
  on public.yearly_readings (owner_user_id, created_at desc);

alter table public.yearly_readings enable row level security;

create table if not exists public.active_phase_readings (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  numerology_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  phase_key text not null,
  phase_start_date date,
  phase_end_date date,
  timezone text not null,
  engine_version text not null,
  active_peak_number smallint,
  active_challenge_number smallint,
  headline text not null,
  summary_text text not null,
  peak_text text,
  challenge_text text,
  guidance_json jsonb not null,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  model_name text,
  prompt_version text,
  generated_at timestamptz not null,
  created_at timestamptz not null default now()
);

create unique index if not exists active_phase_readings_profile_phase_engine_uidx
  on public.active_phase_readings (numerology_profile_id, phase_key, engine_version);

create index if not exists active_phase_readings_owner_created_idx
  on public.active_phase_readings (owner_user_id, created_at desc);

alter table public.active_phase_readings enable row level security;

alter table if exists public.numerology_snapshot_narratives
  add column if not exists prompt_template_id uuid references public.prompt_templates(id) on delete set null;

alter table if exists public.daily_readings
  add column if not exists prompt_template_id uuid references public.prompt_templates(id) on delete set null;

alter table if exists public.compatibility_reports
  add column if not exists prompt_template_id uuid references public.prompt_templates(id) on delete set null;

alter table if exists public.ai_generation_runs
  add column if not exists prompt_template_id uuid references public.prompt_templates(id) on delete set null;

alter table if exists public.ai_generation_runs
  add column if not exists prompt_key text;

alter table if exists public.ai_generation_runs
  add column if not exists system_prompt_snapshot text;

alter table if exists public.ai_generation_runs
  add column if not exists task_prompt_snapshot text;

alter table if exists public.ai_threads
  add column if not exists thread_summary text;

alter table if exists public.ai_threads
  add column if not exists thread_summary_updated_at timestamptz;

alter table if exists public.ai_messages
  add column if not exists prompt_template_id uuid references public.prompt_templates(id) on delete set null;

create index if not exists ai_generation_runs_prompt_template_created_idx
  on public.ai_generation_runs (prompt_template_id, created_at desc);

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'monthly_readings'
      and policyname = 'monthly_readings_select_own'
  ) then
    create policy monthly_readings_select_own
      on public.monthly_readings
      for select
      to authenticated
      using (owner_user_id = auth.uid());
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'yearly_readings'
      and policyname = 'yearly_readings_select_own'
  ) then
    create policy yearly_readings_select_own
      on public.yearly_readings
      for select
      to authenticated
      using (owner_user_id = auth.uid());
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'active_phase_readings'
      and policyname = 'active_phase_readings_select_own'
  ) then
    create policy active_phase_readings_select_own
      on public.active_phase_readings
      for select
      to authenticated
      using (owner_user_id = auth.uid());
  end if;
end
$$;
