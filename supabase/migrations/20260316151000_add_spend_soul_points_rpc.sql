create table if not exists public.soul_point_spend_events (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete cascade,
  request_id text not null,
  amount integer not null check (amount > 0),
  source_type text not null,
  metadata_json jsonb not null default '{}'::jsonb,
  balance_after integer not null check (balance_after >= 0),
  created_at timestamptz not null default now(),
  unique (owner_user_id, request_id)
);

create index if not exists soul_point_spend_events_owner_created_idx
  on public.soul_point_spend_events (owner_user_id, created_at desc);

alter table public.soul_point_spend_events enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'soul_point_spend_events'
      and policyname = 'soul_point_spend_events_select_own'
  ) then
    create policy soul_point_spend_events_select_own
      on public.soul_point_spend_events for select to authenticated
      using ((select auth.uid()) is not null and (select auth.uid()) = owner_user_id);
  end if;
end
$$;

create or replace function public.spend_soul_points(
  p_amount integer,
  p_source_type text default 'manual_adjustment',
  p_request_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := now();
  v_balance integer := 0;
  v_next_balance integer := 0;
  v_existing_balance integer := 0;
  v_clean_request_id text := nullif(trim(p_request_id), '');
  v_source_type text := coalesce(nullif(trim(p_source_type), ''), 'manual_adjustment');
begin
  if v_user_id is null then
    raise exception 'unauthorized';
  end if;

  if p_amount is null or p_amount <= 0 then
    raise exception 'invalid_amount';
  end if;

  if v_clean_request_id is not null then
    select e.balance_after
    into v_existing_balance
    from public.soul_point_spend_events e
    where e.owner_user_id = v_user_id
      and e.request_id = v_clean_request_id
    order by e.created_at desc
    limit 1;

    if found then
      return jsonb_build_object(
        'applied', false,
        'idempotent', true,
        'insufficient', false,
        'required', p_amount,
        'charged', 0,
        'soulPoints', greatest(v_existing_balance, 0)
      );
    end if;
  end if;

  insert into public.soul_point_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select w.balance
  into v_balance
  from public.soul_point_wallets w
  where w.user_id = v_user_id
  for update;

  v_balance := coalesce(v_balance, 0);
  if v_balance < p_amount then
    return jsonb_build_object(
      'applied', false,
      'idempotent', false,
      'insufficient', true,
      'required', p_amount,
      'charged', 0,
      'soulPoints', greatest(v_balance, 0)
    );
  end if;

  v_next_balance := v_balance - p_amount;

  update public.soul_point_wallets
  set balance = v_next_balance,
      lifetime_spent = lifetime_spent + p_amount,
      updated_at = v_now
  where user_id = v_user_id;

  insert into public.soul_point_spend_events (
    owner_user_id,
    request_id,
    amount,
    source_type,
    metadata_json,
    balance_after,
    created_at
  )
  values (
    v_user_id,
    coalesce(v_clean_request_id, gen_random_uuid()::text),
    p_amount,
    v_source_type,
    coalesce(p_metadata, '{}'::jsonb),
    v_next_balance,
    v_now
  );

  return jsonb_build_object(
    'applied', true,
    'idempotent', false,
    'insufficient', false,
    'required', p_amount,
    'charged', p_amount,
    'soulPoints', greatest(v_next_balance, 0)
  );
exception
  when unique_violation then
    if v_clean_request_id is not null then
      select e.balance_after
      into v_existing_balance
      from public.soul_point_spend_events e
      where e.owner_user_id = v_user_id
        and e.request_id = v_clean_request_id
      order by e.created_at desc
      limit 1;

      if found then
        return jsonb_build_object(
          'applied', false,
          'idempotent', true,
          'insufficient', false,
          'required', p_amount,
          'charged', 0,
          'soulPoints', greatest(v_existing_balance, 0)
        );
      end if;
    end if;
    raise;
end;
$$;

revoke all on function public.spend_soul_points(integer, text, text, jsonb) from public;
revoke all on function public.spend_soul_points(integer, text, text, jsonb) from anon;
grant execute on function public.spend_soul_points(integer, text, text, jsonb) to authenticated;
grant execute on function public.spend_soul_points(integer, text, text, jsonb) to service_role;
