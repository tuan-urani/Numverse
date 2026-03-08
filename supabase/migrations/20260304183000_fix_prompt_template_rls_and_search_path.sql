create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
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
