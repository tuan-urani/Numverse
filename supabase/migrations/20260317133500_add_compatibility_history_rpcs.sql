create table if not exists public.compatibility_history_items (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  request_id text,
  primary_profile_id text not null,
  primary_name text not null,
  primary_birth_date date not null,
  primary_life_path integer not null,
  primary_soul integer not null,
  primary_personality integer not null,
  primary_expression integer not null,
  target_profile_id text not null,
  target_name text not null,
  target_relation text not null,
  target_birth_date date not null,
  target_life_path integer not null,
  target_soul integer not null,
  target_personality integer not null,
  target_expression integer not null,
  overall_score smallint not null check (overall_score between 0 and 100),
  core_score smallint not null check (core_score between 0 and 100),
  communication_score smallint not null check (communication_score between 0 and 100),
  soul_score smallint not null check (soul_score between 0 and 100),
  personality_score smallint not null check (personality_score between 0 and 100),
  created_at timestamptz not null default now()
);

create unique index if not exists compatibility_history_items_owner_request_uidx
  on public.compatibility_history_items (owner_user_id, request_id);

create index if not exists compatibility_history_items_owner_created_idx
  on public.compatibility_history_items (owner_user_id, created_at desc);

alter table public.compatibility_history_items enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'compatibility_history_items'
      and policyname = 'compatibility_history_items_select_own'
  ) then
    create policy compatibility_history_items_select_own
      on public.compatibility_history_items
      for select
      to authenticated
      using (owner_user_id = auth.uid());
  end if;
end
$$;

grant select on table public.compatibility_history_items to authenticated;
grant select on table public.compatibility_history_items to service_role;

create or replace function public.save_compatibility_history(
  p_payload jsonb,
  p_request_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := now();
  v_request_id text := nullif(trim(coalesce(p_request_id, p_payload ->> 'requestId')), '');
  v_primary_profile_id text := nullif(trim(p_payload ->> 'primaryProfileId'), '');
  v_primary_name text := nullif(trim(p_payload ->> 'primaryName'), '');
  v_primary_birth_text text := nullif(trim(p_payload ->> 'primaryBirthDate'), '');
  v_primary_birth_date date;
  v_primary_life_path integer;
  v_primary_soul integer;
  v_primary_personality integer;
  v_primary_expression integer;
  v_target_profile_id text := nullif(trim(p_payload ->> 'targetProfileId'), '');
  v_target_name text := nullif(trim(p_payload ->> 'targetName'), '');
  v_target_relation text := nullif(trim(p_payload ->> 'targetRelation'), '');
  v_target_birth_text text := nullif(trim(p_payload ->> 'targetBirthDate'), '');
  v_target_birth_date date;
  v_target_life_path integer;
  v_target_soul integer;
  v_target_personality integer;
  v_target_expression integer;
  v_overall_score integer;
  v_core_score integer;
  v_communication_score integer;
  v_soul_score integer;
  v_personality_score integer;
  v_created_at timestamptz := v_now;
  v_row public.compatibility_history_items%rowtype;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if jsonb_typeof(p_payload) <> 'object' then
    raise exception 'invalid_payload';
  end if;

  if v_primary_profile_id is null then
    raise exception 'invalid_primary_profile_id';
  end if;
  if v_primary_name is null then
    raise exception 'invalid_primary_name';
  end if;
  if v_primary_birth_text is null then
    raise exception 'invalid_primary_birth_date';
  end if;
  if v_target_profile_id is null then
    raise exception 'invalid_target_profile_id';
  end if;
  if v_target_name is null then
    raise exception 'invalid_target_name';
  end if;
  if v_target_relation is null then
    raise exception 'invalid_target_relation';
  end if;
  if v_target_birth_text is null then
    raise exception 'invalid_target_birth_date';
  end if;

  if nullif(trim(p_payload ->> 'createdAt'), '') is not null then
    begin
      v_created_at := (p_payload ->> 'createdAt')::timestamptz;
    exception
      when others then
        v_created_at := v_now;
    end;
  end if;

  begin
    v_primary_birth_date := substring(v_primary_birth_text from 1 for 10)::date;
  exception
    when others then
      raise exception 'invalid_primary_birth_date';
  end;

  begin
    v_target_birth_date := substring(v_target_birth_text from 1 for 10)::date;
  exception
    when others then
      raise exception 'invalid_target_birth_date';
  end;

  begin
    v_primary_life_path := (p_payload ->> 'primaryLifePath')::integer;
    v_primary_soul := (p_payload ->> 'primarySoul')::integer;
    v_primary_personality := (p_payload ->> 'primaryPersonality')::integer;
    v_primary_expression := (p_payload ->> 'primaryExpression')::integer;
    v_target_life_path := (p_payload ->> 'targetLifePath')::integer;
    v_target_soul := (p_payload ->> 'targetSoul')::integer;
    v_target_personality := (p_payload ->> 'targetPersonality')::integer;
    v_target_expression := (p_payload ->> 'targetExpression')::integer;
    v_overall_score := (p_payload ->> 'overallScore')::integer;
    v_core_score := (p_payload ->> 'coreScore')::integer;
    v_communication_score := (p_payload ->> 'communicationScore')::integer;
    v_soul_score := (p_payload ->> 'soulScore')::integer;
    v_personality_score := (p_payload ->> 'personalityScore')::integer;
  exception
    when others then
      raise exception 'invalid_score_payload';
  end;

  if v_primary_life_path is null
    or v_primary_soul is null
    or v_primary_personality is null
    or v_primary_expression is null
    or v_target_life_path is null
    or v_target_soul is null
    or v_target_personality is null
    or v_target_expression is null
    or v_overall_score is null
    or v_core_score is null
    or v_communication_score is null
    or v_soul_score is null
    or v_personality_score is null then
    raise exception 'invalid_score_payload';
  end if;

  insert into public.compatibility_history_items (
    owner_user_id,
    request_id,
    primary_profile_id,
    primary_name,
    primary_birth_date,
    primary_life_path,
    primary_soul,
    primary_personality,
    primary_expression,
    target_profile_id,
    target_name,
    target_relation,
    target_birth_date,
    target_life_path,
    target_soul,
    target_personality,
    target_expression,
    overall_score,
    core_score,
    communication_score,
    soul_score,
    personality_score,
    created_at
  )
  values (
    v_user_id,
    v_request_id,
    v_primary_profile_id,
    v_primary_name,
    v_primary_birth_date,
    v_primary_life_path,
    v_primary_soul,
    v_primary_personality,
    v_primary_expression,
    v_target_profile_id,
    v_target_name,
    v_target_relation,
    v_target_birth_date,
    v_target_life_path,
    v_target_soul,
    v_target_personality,
    v_target_expression,
    v_overall_score,
    v_core_score,
    v_communication_score,
    v_soul_score,
    v_personality_score,
    v_created_at
  )
  on conflict (owner_user_id, request_id) do update
    set primary_profile_id = excluded.primary_profile_id,
        primary_name = excluded.primary_name,
        primary_birth_date = excluded.primary_birth_date,
        primary_life_path = excluded.primary_life_path,
        primary_soul = excluded.primary_soul,
        primary_personality = excluded.primary_personality,
        primary_expression = excluded.primary_expression,
        target_profile_id = excluded.target_profile_id,
        target_name = excluded.target_name,
        target_relation = excluded.target_relation,
        target_birth_date = excluded.target_birth_date,
        target_life_path = excluded.target_life_path,
        target_soul = excluded.target_soul,
        target_personality = excluded.target_personality,
        target_expression = excluded.target_expression,
        overall_score = excluded.overall_score,
        core_score = excluded.core_score,
        communication_score = excluded.communication_score,
        soul_score = excluded.soul_score,
        personality_score = excluded.personality_score,
        created_at = excluded.created_at
  returning * into v_row;

  return jsonb_build_object(
    'id', v_row.id::text,
    'requestId', coalesce(v_row.request_id, ''),
    'primaryProfileId', v_row.primary_profile_id,
    'primaryName', v_row.primary_name,
    'primaryBirthDate', (v_row.primary_birth_date::text || 'T00:00:00.000'),
    'primaryLifePath', v_row.primary_life_path,
    'primarySoul', v_row.primary_soul,
    'primaryPersonality', v_row.primary_personality,
    'primaryExpression', v_row.primary_expression,
    'targetProfileId', v_row.target_profile_id,
    'targetName', v_row.target_name,
    'targetRelation', v_row.target_relation,
    'targetBirthDate', (v_row.target_birth_date::text || 'T00:00:00.000'),
    'targetLifePath', v_row.target_life_path,
    'targetSoul', v_row.target_soul,
    'targetPersonality', v_row.target_personality,
    'targetExpression', v_row.target_expression,
    'overallScore', v_row.overall_score,
    'coreScore', v_row.core_score,
    'communicationScore', v_row.communication_score,
    'soulScore', v_row.soul_score,
    'personalityScore', v_row.personality_score,
    'createdAt', v_row.created_at
  );
end;
$$;

create or replace function public.get_compatibility_history(
  p_limit integer default 30
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_limit integer := least(greatest(coalesce(p_limit, 30), 1), 200);
  v_items jsonb := '[]'::jsonb;
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', h.id::text,
        'requestId', coalesce(h.request_id, ''),
        'primaryProfileId', h.primary_profile_id,
        'primaryName', h.primary_name,
        'primaryBirthDate', (h.primary_birth_date::text || 'T00:00:00.000'),
        'primaryLifePath', h.primary_life_path,
        'primarySoul', h.primary_soul,
        'primaryPersonality', h.primary_personality,
        'primaryExpression', h.primary_expression,
        'targetProfileId', h.target_profile_id,
        'targetName', h.target_name,
        'targetRelation', h.target_relation,
        'targetBirthDate', (h.target_birth_date::text || 'T00:00:00.000'),
        'targetLifePath', h.target_life_path,
        'targetSoul', h.target_soul,
        'targetPersonality', h.target_personality,
        'targetExpression', h.target_expression,
        'overallScore', h.overall_score,
        'coreScore', h.core_score,
        'communicationScore', h.communication_score,
        'soulScore', h.soul_score,
        'personalityScore', h.personality_score,
        'createdAt', h.created_at
      )
      order by h.created_at desc
    ),
    '[]'::jsonb
  )
  into v_items
  from (
    select *
    from public.compatibility_history_items
    where owner_user_id = v_user_id
    order by created_at desc
    limit v_limit
  ) h;

  return v_items;
end;
$$;

revoke all on function public.save_compatibility_history(jsonb, text) from public;
revoke all on function public.save_compatibility_history(jsonb, text) from anon;
grant execute on function public.save_compatibility_history(jsonb, text) to authenticated;
grant execute on function public.save_compatibility_history(jsonb, text) to service_role;

revoke all on function public.get_compatibility_history(integer) from public;
revoke all on function public.get_compatibility_history(integer) from anon;
grant execute on function public.get_compatibility_history(integer) to authenticated;
grant execute on function public.get_compatibility_history(integer) to service_role;
