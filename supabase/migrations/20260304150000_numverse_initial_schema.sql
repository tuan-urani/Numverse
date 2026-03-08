create extension if not exists pgcrypto;

create type public.profile_kind as enum ('self', 'other');
create type public.relation_kind as enum (
  'self',
  'lover',
  'spouse',
  'friend',
  'mother',
  'father',
  'child',
  'sibling',
  'coworker',
  'other'
);
create type public.subscription_status as enum (
  'trialing',
  'active',
  'grace_period',
  'canceled',
  'expired'
);
create type public.feature_code as enum (
  'today_detail',
  'month_detail',
  'year_detail',
  'active_phase_detail',
  'numai_message'
);
create type public.unlock_source as enum ('subscription', 'soul_point', 'admin');
create type public.ledger_direction as enum ('credit', 'debit');
create type public.ledger_source_type as enum (
  'daily_checkin',
  'streak_bonus',
  'ad_reward',
  'today_unlock',
  'numai_message',
  'manual_adjustment'
);
create type public.ai_context_type as enum ('general', 'today', 'reading', 'compatibility');
create type public.generation_kind as enum (
  'snapshot_narrative',
  'daily_reading_narrative',
  'monthly_reading_narrative',
  'yearly_reading_narrative',
  'active_phase_narrative',
  'compatibility_narrative',
  'numai_reply'
);
create type public.generation_status as enum ('queued', 'running', 'succeeded', 'failed');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.user_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  locale text not null default 'vi-VN',
  timezone text not null default 'Asia/Ho_Chi_Minh',
  onboarding_completed boolean not null default false,
  last_active_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  language text not null default 'vi',
  timezone text not null default 'Asia/Ho_Chi_Minh',
  daily_notification_enabled boolean not null default true,
  daily_notification_time time,
  marketing_opt_in boolean not null default false,
  analytics_opt_in boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null,
  product_code text not null,
  status public.subscription_status not null,
  started_at timestamptz not null,
  expires_at timestamptz,
  auto_renew boolean not null default false,
  provider_customer_id text,
  provider_subscription_id text,
  entitlements_json jsonb not null default '{}'::jsonb,
  last_verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.numerology_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  profile_kind public.profile_kind not null,
  relation_kind public.relation_kind not null default 'self',
  display_name text not null,
  full_name_for_reading text not null,
  birth_date date not null,
  gender text,
  is_primary boolean not null default false,
  notes text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.numerology_snapshots (
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

create table public.prompt_templates (
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

create table public.ai_generation_runs (
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

create table public.numerology_snapshot_narratives (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  numerology_snapshot_id uuid not null references public.numerology_snapshots(id) on delete cascade,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  locale text not null default 'vi-VN',
  model_provider text not null default 'gemini',
  model_name text not null,
  prompt_version text not null,
  schema_version text,
  status public.generation_status not null,
  is_current boolean not null default true,
  sections_json jsonb not null,
  generated_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.daily_readings (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  numerology_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  local_date date not null,
  timezone text not null,
  engine_version text not null,
  personal_year smallint not null,
  personal_month smallint not null,
  personal_day smallint not null,
  active_peak_number smallint,
  active_challenge_number smallint,
  hero_text text not null,
  energy_score smallint,
  daily_rhythm text,
  daily_insight_short text not null,
  daily_insight_full text,
  action_do_json jsonb not null,
  action_avoid_json jsonb not null,
  month_context_json jsonb not null,
  year_context_json jsonb not null,
  active_phase_json jsonb,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  model_name text,
  prompt_version text,
  generated_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table public.monthly_readings (
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

create table public.yearly_readings (
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

create table public.active_phase_readings (
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

create table public.feature_unlocks (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  numerology_profile_id uuid references public.numerology_profiles(id) on delete cascade,
  feature_code public.feature_code not null,
  scope_key text not null,
  unlock_source public.unlock_source not null,
  soul_point_cost integer,
  starts_at timestamptz not null,
  expires_at timestamptz not null,
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.soul_point_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  lifetime_earned integer not null default 0 check (lifetime_earned >= 0),
  lifetime_spent integer not null default 0 check (lifetime_spent >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.soul_point_ledger (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  direction public.ledger_direction not null,
  amount integer not null check (amount > 0),
  source_type public.ledger_source_type not null,
  source_ref_id uuid,
  balance_after integer not null check (balance_after >= 0),
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.daily_checkins (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  local_date date not null,
  streak_count integer not null check (streak_count >= 0),
  reward_amount integer not null check (reward_amount >= 0),
  created_at timestamptz not null default now()
);

create table public.ad_reward_events (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  ad_network text not null,
  placement_code text not null,
  reward_amount integer not null check (reward_amount >= 0),
  status text not null check (status in ('pending', 'granted', 'rejected')),
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.compatibility_reports (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  primary_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  target_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  engine_version text not null,
  score smallint not null check (score between 0 and 100),
  compatibility_structure_json jsonb not null default '{}'::jsonb,
  summary text not null,
  strengths_json jsonb not null,
  tensions_json jsonb not null,
  guidance_json jsonb not null,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  model_name text,
  prompt_version text,
  calculated_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

create table public.ai_threads (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  primary_profile_id uuid not null references public.numerology_profiles(id) on delete cascade,
  related_profile_id uuid references public.numerology_profiles(id) on delete set null,
  context_type public.ai_context_type not null default 'general',
  title text,
  thread_summary text,
  thread_summary_updated_at timestamptz,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  thread_id uuid not null references public.ai_threads(id) on delete cascade,
  sender_type text not null check (sender_type in ('user', 'assistant', 'system')),
  message_text text not null,
  context_snapshot_id uuid references public.numerology_snapshots(id) on delete set null,
  context_daily_reading_id uuid references public.daily_readings(id) on delete set null,
  context_compatibility_report_id uuid references public.compatibility_reports(id) on delete set null,
  ai_generation_run_id uuid references public.ai_generation_runs(id) on delete set null,
  prompt_template_id uuid references public.prompt_templates(id) on delete set null,
  soul_point_cost integer not null default 0 check (soul_point_cost >= 0),
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.content_templates (
  id uuid primary key default gen_random_uuid(),
  domain text not null,
  template_key text not null,
  locale text not null default 'vi-VN',
  title text not null,
  summary_template text not null,
  body_template text not null,
  metadata_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index numerology_profiles_one_primary_uidx
  on public.numerology_profiles (owner_user_id)
  where is_primary = true and archived_at is null;

create unique index numerology_snapshots_current_uidx
  on public.numerology_snapshots (numerology_profile_id)
  where is_current = true;

create index numerology_snapshots_profile_current_idx
  on public.numerology_snapshots (numerology_profile_id, is_current);

create index numerology_snapshots_owner_profile_created_idx
  on public.numerology_snapshots (owner_user_id, numerology_profile_id, created_at desc);

create unique index numerology_snapshot_narratives_current_uidx
  on public.numerology_snapshot_narratives (numerology_snapshot_id)
  where is_current = true;

create index numerology_snapshot_narratives_owner_generated_idx
  on public.numerology_snapshot_narratives (owner_user_id, generated_at desc);

create unique index daily_readings_profile_date_engine_uidx
  on public.daily_readings (numerology_profile_id, local_date, engine_version);

create unique index monthly_readings_profile_year_month_engine_uidx
  on public.monthly_readings (numerology_profile_id, local_year, local_month, engine_version);

create unique index yearly_readings_profile_year_engine_uidx
  on public.yearly_readings (numerology_profile_id, local_year, engine_version);

create unique index active_phase_readings_profile_phase_engine_uidx
  on public.active_phase_readings (numerology_profile_id, phase_key, engine_version);

create unique index feature_unlocks_scope_uidx
  on public.feature_unlocks (owner_user_id, numerology_profile_id, feature_code, scope_key);

create index soul_point_ledger_owner_created_idx
  on public.soul_point_ledger (owner_user_id, created_at desc);

create unique index daily_checkins_owner_date_uidx
  on public.daily_checkins (owner_user_id, local_date);

create unique index compatibility_reports_owner_pair_engine_uidx
  on public.compatibility_reports (owner_user_id, primary_profile_id, target_profile_id, engine_version);

create unique index prompt_templates_prompt_key_locale_version_uidx
  on public.prompt_templates (prompt_key, locale, version);

create unique index prompt_templates_one_active_uidx
  on public.prompt_templates (prompt_key, locale)
  where status = 'active';

create index ai_generation_runs_owner_created_idx
  on public.ai_generation_runs (owner_user_id, created_at desc);

create index ai_generation_runs_target_idx
  on public.ai_generation_runs (target_table, target_id);

create index ai_generation_runs_prompt_template_created_idx
  on public.ai_generation_runs (prompt_template_id, created_at desc);

create index ai_threads_owner_updated_idx
  on public.ai_threads (owner_user_id, updated_at desc);

create index ai_messages_thread_created_idx
  on public.ai_messages (thread_id, created_at);

create index subscriptions_owner_status_idx
  on public.subscriptions (owner_user_id, status, expires_at desc);

create trigger set_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_updated_at();

create trigger set_user_settings_updated_at
before update on public.user_settings
for each row execute function public.set_updated_at();

create trigger set_subscriptions_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

create trigger set_numerology_profiles_updated_at
before update on public.numerology_profiles
for each row execute function public.set_updated_at();

create trigger set_prompt_templates_updated_at
before update on public.prompt_templates
for each row execute function public.set_updated_at();

create trigger set_snapshot_narratives_updated_at
before update on public.numerology_snapshot_narratives
for each row execute function public.set_updated_at();

create trigger set_soul_point_wallets_updated_at
before update on public.soul_point_wallets
for each row execute function public.set_updated_at();

create trigger set_ai_threads_updated_at
before update on public.ai_threads
for each row execute function public.set_updated_at();

create trigger set_content_templates_updated_at
before update on public.content_templates
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', new.raw_user_meta_data ->> 'name'))
  on conflict (id) do nothing;

  insert into public.user_settings (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.soul_point_wallets (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

alter table public.user_profiles enable row level security;
alter table public.user_settings enable row level security;
alter table public.subscriptions enable row level security;
alter table public.numerology_profiles enable row level security;
alter table public.numerology_snapshots enable row level security;
alter table public.numerology_snapshot_narratives enable row level security;
alter table public.daily_readings enable row level security;
alter table public.monthly_readings enable row level security;
alter table public.yearly_readings enable row level security;
alter table public.active_phase_readings enable row level security;
alter table public.feature_unlocks enable row level security;
alter table public.soul_point_wallets enable row level security;
alter table public.soul_point_ledger enable row level security;
alter table public.daily_checkins enable row level security;
alter table public.ad_reward_events enable row level security;
alter table public.compatibility_reports enable row level security;
alter table public.prompt_templates enable row level security;
alter table public.ai_generation_runs enable row level security;
alter table public.ai_threads enable row level security;
alter table public.ai_messages enable row level security;
alter table public.content_templates enable row level security;

create policy user_profiles_select_own
  on public.user_profiles for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = id);

create policy user_profiles_insert_own
  on public.user_profiles for insert to authenticated
  with check ((select auth.uid()) is not null and (select auth.uid()) = id);

create policy user_profiles_update_own
  on public.user_profiles for update to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = id)
  with check ((select auth.uid()) is not null and (select auth.uid()) = id);

create policy user_settings_select_own
  on public.user_settings for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy user_settings_insert_own
  on public.user_settings for insert to authenticated
  with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy user_settings_update_own
  on public.user_settings for update to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
  with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy subscriptions_select_own
  on public.subscriptions for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy numerology_profiles_select_own
  on public.numerology_profiles for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy numerology_profiles_insert_own
  on public.numerology_profiles for insert to authenticated
  with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy numerology_profiles_update_own
  on public.numerology_profiles for update to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id)
  with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy numerology_profiles_delete_own
  on public.numerology_profiles for delete to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy numerology_snapshots_select_own
  on public.numerology_snapshots for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy numerology_snapshot_narratives_select_own
  on public.numerology_snapshot_narratives for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy daily_readings_select_own
  on public.daily_readings for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy monthly_readings_select_own
  on public.monthly_readings for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy yearly_readings_select_own
  on public.yearly_readings for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy active_phase_readings_select_own
  on public.active_phase_readings for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy feature_unlocks_select_own
  on public.feature_unlocks for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy soul_point_wallets_select_own
  on public.soul_point_wallets for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

create policy soul_point_ledger_select_own
  on public.soul_point_ledger for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy daily_checkins_select_own
  on public.daily_checkins for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ad_reward_events_select_own
  on public.ad_reward_events for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy compatibility_reports_select_own
  on public.compatibility_reports for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ai_generation_runs_select_own
  on public.ai_generation_runs for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ai_threads_select_own
  on public.ai_threads for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ai_threads_insert_own
  on public.ai_threads for insert to authenticated
  with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ai_threads_update_own
  on public.ai_threads for update to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id)
  with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ai_threads_delete_own
  on public.ai_threads for delete to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ai_messages_select_own
  on public.ai_messages for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy ai_messages_insert_own
  on public.ai_messages for insert to authenticated
  with check ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);

create policy content_templates_select_authenticated
  on public.content_templates for select to authenticated
  using (true);
