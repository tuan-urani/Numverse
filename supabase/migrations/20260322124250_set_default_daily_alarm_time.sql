alter table public.user_settings
  alter column daily_notification_time set default '08:00:00'::time;

update public.user_settings
set daily_notification_time = '08:00:00'::time,
    updated_at = now()
where daily_notification_time is null;
