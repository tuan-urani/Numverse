begin;

alter table if exists public.ai_threads
  drop column if exists context_type;

drop type if exists public.ai_context_type;

update public.ai_messages
set metadata_json = metadata_json - 'context_type'
where metadata_json ? 'context_type';

update public.prompt_templates
set
  context_schema_json = jsonb_set(
    context_schema_json #- '{properties,context_type}',
    '{required}',
    coalesce(
      (
        select jsonb_agg(required_item)
        from jsonb_array_elements(
          coalesce(context_schema_json->'required', '[]'::jsonb)
        ) as required_item
        where required_item <> to_jsonb('context_type'::text)
      ),
      '[]'::jsonb
    ),
    true
  ),
  task_prompt_template = replace(
    replace(
      task_prompt_template,
      'thread_summary, recent_messages, active_profile, snapshot_facts, user_question, context_type',
      'thread_summary, recent_messages, active_profile, snapshot_facts, user_question'
    ),
    'Nếu context_type là today hoặc compatibility nhưng context hiện chưa có dữ liệu chuyên biệt, hãy trả lời dựa trên snapshot_facts và nói theo hướng thận trọng.',
    'Nếu context hiện chưa có dữ liệu chuyên biệt, hãy trả lời dựa trên snapshot_facts và nói theo hướng thận trọng.'
  ),
  updated_at = now()
where prompt_key = 'numai_chat_reply';

commit;
