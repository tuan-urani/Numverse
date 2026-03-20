do $$
declare
  v_bootstrap_def text;
  v_snapshot_def text;
begin
  select pg_get_functiondef('public.sync_local_session_bootstrap(jsonb)'::regprocedure)
  into v_bootstrap_def;

  if v_bootstrap_def is null then
    raise exception 'function_not_found:sync_local_session_bootstrap';
  end if;

  v_bootstrap_def := regexp_replace(
    v_bootstrap_def,
    'v_profile_limit integer := [0-9]+;',
    'v_profile_limit integer := 100;',
    'g'
  );

  execute v_bootstrap_def;

  select pg_get_functiondef('public.sync_local_session_snapshot(jsonb)'::regprocedure)
  into v_snapshot_def;

  if v_snapshot_def is null then
    raise exception 'function_not_found:sync_local_session_snapshot';
  end if;

  v_snapshot_def := regexp_replace(
    v_snapshot_def,
    'v_profile_limit integer := [0-9]+;',
    'v_profile_limit integer := 100;',
    'g'
  );

  execute v_snapshot_def;
end;
$$;
