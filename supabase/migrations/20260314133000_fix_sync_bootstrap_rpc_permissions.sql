revoke all on function public.sync_local_session_bootstrap(jsonb) from public;
revoke all on function public.sync_local_session_bootstrap(jsonb) from anon;
grant execute on function public.sync_local_session_bootstrap(jsonb) to authenticated;
grant execute on function public.sync_local_session_bootstrap(jsonb) to service_role;
