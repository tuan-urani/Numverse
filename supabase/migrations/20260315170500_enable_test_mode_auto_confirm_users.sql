-- Test mode: automatically confirm email for newly created auth users.
-- NOTE: Keep this only for testing environments.

create or replace function public.set_auth_user_email_confirmed_for_test_mode()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_auth_users_auto_confirm_test_mode on auth.users;

create trigger trg_auth_users_auto_confirm_test_mode
before insert on auth.users
for each row
execute function public.set_auth_user_email_confirmed_for_test_mode();

update auth.users
set email_confirmed_at = now()
where email_confirmed_at is null
  and deleted_at is null;
