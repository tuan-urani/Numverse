begin;

insert into public.prompt_templates (
  prompt_key,
  version,
  locale,
  status,
  provider,
  model_name,
  temperature,
  max_output_tokens,
  system_prompt,
  task_prompt_template,
  context_schema_json,
  output_schema_json,
  notes,
  created_by,
  created_at,
  updated_at
)
values
  (
    'life_snapshot_narrative',
    'v1',
    'vi-VN',
    'active',
    'gemini',
    'gemini-2.5-pro',
    0.40,
    2500,
    $system$
Bạn là Numverse AI narrative engine.

Nhiệm vụ của bạn là diễn giải thần số học bằng tiếng Việt tự nhiên, rõ ràng, cân bằng, dễ hiểu.

Quy tắc bắt buộc:
- Chỉ được diễn giải từ facts được cung cấp trong context JSON.
- Không tự tính lại numerology.
- Không bịa thêm chỉ số, chu kỳ, hay kết luận không có trong facts.
- Không dùng giọng văn khẳng định tuyệt đối.
- Không dùng văn phong quá thần bí, định mệnh, hoặc gây sợ hãi.
- Hãy viết theo hướng self-discovery, reflection, thực tế, dễ áp dụng.
- Trả về JSON hợp lệ, đúng đúng schema đã yêu cầu.
    $system$,
    $task$
Hãy tạo narrative life-based cho hồ sơ numerology của người dùng để hiển thị trong tab "Luận giải".

Mục tiêu:
- Giải thích rõ 4 nhóm: Chỉ số cốt lõi, Biểu đồ và ma trận, Lộ trình cuộc đời, Chân dung cá nhân.
- Biến bộ số deterministic thành ngôn ngữ đời sống, dễ hiểu với người dùng phổ thông Việt Nam.
- Nêu được điểm mạnh, điểm cần cân bằng, phong cách giao tiếp, tình cảm, và định hướng công việc.
- Tạo thêm compact_summary để tái sử dụng cho các chức năng time-based và compatibility.

Yêu cầu nội dung:
- Từng section phải bám chặt vào facts.
- Mỗi đoạn nên ngắn gọn, tránh lặp ý.
- strengths, balance_points, top_strengths, top_balance_points nên là các ý cụ thể, không trừu tượng.
- Không nhắc đến context JSON hay schema trong output.
- Chỉ trả về JSON hợp lệ.
    $task$,
    $json$
{
  "type": "object",
  "required": ["profile", "snapshot"],
  "properties": {
    "profile": {
      "type": "object",
      "required": ["profile_id", "display_name", "locale"],
      "properties": {
        "profile_id": { "type": "string" },
        "display_name": { "type": "string" },
        "locale": { "type": "string" }
      }
    },
    "snapshot": {
      "type": "object",
      "required": ["snapshot_id", "core_numbers", "birth_matrix", "matrix_aspects", "life_cycles"],
      "properties": {
        "snapshot_id": { "type": "string" },
        "core_numbers": { "type": "object" },
        "birth_matrix": { "type": "object" },
        "matrix_aspects": { "type": "object" },
        "life_cycles": { "type": "object" }
      }
    }
  }
}
    $json$::jsonb,
    $json$
{
  "type": "object",
  "required": ["core_numbers", "birth_matrix", "matrix_aspects", "life_cycles", "persona", "compact_summary"],
  "properties": {
    "core_numbers": { "type": "object" },
    "birth_matrix": { "type": "object" },
    "matrix_aspects": { "type": "object" },
    "life_cycles": { "type": "object" },
    "persona": { "type": "object" },
    "compact_summary": {
      "type": "object",
      "required": ["identity_summary", "top_strengths", "top_balance_points"],
      "properties": {
        "identity_summary": { "type": "string" },
        "top_strengths": {
          "type": "array",
          "items": { "type": "string" }
        },
        "top_balance_points": {
          "type": "array",
          "items": { "type": "string" }
        }
      }
    }
  }
}
    $json$::jsonb,
    'Life-based narrative cho tab Luận giải. Dùng model mạnh hơn vì generate ít lần nhưng cần chiều sâu.',
    null,
    now(),
    now()
  ),
  (
    'daily_reading_narrative',
    'v1',
    'vi-VN',
    'active',
    'gemini',
    'gemini-2.5-flash',
    0.30,
    900,
    $system$
Bạn là Numverse AI narrative engine.

Nhiệm vụ của bạn là tạo nội dung ngắn, rõ, dễ đọc cho tab "Hôm nay".

Quy tắc bắt buộc:
- Chỉ được diễn giải từ facts được cung cấp.
- Không tự tính lại numerology.
- Ưu tiên khả năng đọc nhanh trong 10 giây đầu tiên.
- Không viết dài dòng như một bài luận.
- Không khẳng định tuyệt đối.
- Trả về JSON hợp lệ, đúng schema.
    $system$,
    $task$
Hãy tạo narrative cho tab "Hôm nay".

Mục tiêu:
- Tạo quick layer gồm hero_text, energy_score, daily_rhythm, daily_insight_short.
- Tạo action layer gồm action_do và action_avoid.
- Tạo preview context layer gồm month_context, year_context, active_phase.

Yêu cầu nội dung:
- hero_text ngắn, súc tích, phù hợp hiển thị trong hero card.
- daily_insight_short phải đủ hữu ích cho free user.
- action_do và action_avoid chỉ nên có đúng 2 ý chính mỗi nhóm.
- month_context, year_context, active_phase chỉ là các preview ngắn, không bung dài.
- Chỉ trả về JSON hợp lệ.
    $task$,
    $json$
{
  "type": "object",
  "required": ["profile", "date_context"],
  "properties": {
    "profile": {
      "type": "object",
      "required": ["profile_id", "display_name", "locale", "timezone"],
      "properties": {
        "profile_id": { "type": "string" },
        "display_name": { "type": "string" },
        "locale": { "type": "string" },
        "timezone": { "type": "string" }
      }
    },
    "date_context": {
      "type": "object",
      "required": ["local_date", "personal_year", "personal_month", "personal_day"],
      "properties": {
        "local_date": { "type": "string" },
        "personal_year": { "type": "number" },
        "personal_month": { "type": "number" },
        "personal_day": { "type": "number" },
        "active_peak_number": { "type": ["number", "null"] },
        "active_challenge_number": { "type": ["number", "null"] }
      }
    },
    "life_summary_compact": {
      "type": ["object", "null"]
    }
  }
}
    $json$::jsonb,
    $json$
{
  "type": "object",
  "required": [
    "hero_text",
    "energy_score",
    "daily_rhythm",
    "daily_insight_short",
    "daily_insight_full",
    "action_do",
    "action_avoid",
    "month_context",
    "year_context",
    "active_phase"
  ],
  "properties": {
    "hero_text": { "type": "string" },
    "energy_score": { "type": "number" },
    "daily_rhythm": { "type": "string" },
    "daily_insight_short": { "type": "string" },
    "daily_insight_full": { "type": "string" },
    "action_do": {
      "type": "array",
      "items": { "type": "string" }
    },
    "action_avoid": {
      "type": "array",
      "items": { "type": "string" }
    },
    "month_context": { "type": "object" },
    "year_context": { "type": "object" },
    "active_phase": { "type": "object" }
  }
}
    $json$::jsonb,
    'Narrative preview cho tab Hôm nay. Tối ưu cho quick read, free preview, và render hero/action cards.',
    null,
    now(),
    now()
  ),
  (
    'monthly_reading_narrative',
    'v1',
    'vi-VN',
    'active',
    'gemini',
    'gemini-2.5-flash',
    0.35,
    1200,
    $system$
Bạn là Numverse AI narrative engine.

Nhiệm vụ của bạn là tạo nội dung detail cho màn "Chi tiết tháng này".

Quy tắc bắt buộc:
- Chỉ được diễn giải từ facts được cung cấp.
- Không tự tính lại numerology.
- Không lặp lại y nguyên preview ngắn ở home.
- Văn phong phải rõ, có định hướng, nhưng không phán quyết tuyệt đối.
- Trả về JSON hợp lệ theo schema.
    $system$,
    $task$
Hãy tạo narrative chi tiết cho tháng hiện tại.

Mục tiêu:
- Giải thích rõ trọng tâm tháng.
- Tạo phần summary_text và focus_text dễ đọc.
- Nêu opportunities, cautions, và guidance đủ cụ thể để user ứng dụng trong tháng này.

Yêu cầu nội dung:
- Phải dài và sâu hơn preview ở màn home.
- Không biến thành bài luận quá dài.
- Chỉ trả về JSON hợp lệ.
    $task$,
    $json$
{
  "type": "object",
  "required": ["profile", "month_context"],
  "properties": {
    "profile": { "type": "object" },
    "month_context": {
      "type": "object",
      "required": ["local_year", "local_month", "personal_year", "personal_month"],
      "properties": {
        "local_year": { "type": "number" },
        "local_month": { "type": "number" },
        "personal_year": { "type": "number" },
        "personal_month": { "type": "number" }
      }
    },
    "life_summary_compact": {
      "type": ["object", "null"]
    }
  }
}
    $json$::jsonb,
    $json$
{
  "type": "object",
  "required": ["headline", "summary_text", "focus_text", "opportunities", "cautions", "guidance"],
  "properties": {
    "headline": { "type": "string" },
    "summary_text": { "type": "string" },
    "focus_text": { "type": "string" },
    "opportunities": {
      "type": "array",
      "items": { "type": "string" }
    },
    "cautions": {
      "type": "array",
      "items": { "type": "string" }
    },
    "guidance": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
    $json$::jsonb,
    'Narrative detail cho màn Chi tiết tháng này. Cache theo year-month.',
    null,
    now(),
    now()
  ),
  (
    'yearly_reading_narrative',
    'v1',
    'vi-VN',
    'active',
    'gemini',
    'gemini-2.5-flash',
    0.35,
    1400,
    $system$
Bạn là Numverse AI narrative engine.

Nhiệm vụ của bạn là tạo nội dung detail cho màn "Chi tiết năm nay".

Quy tắc bắt buộc:
- Chỉ được diễn giải từ facts được cung cấp.
- Không tự tính lại numerology.
- Không dùng giọng văn khẳng định tuyệt đối.
- Nội dung phải có tính định hướng, thực tế, và dễ áp dụng.
- Trả về JSON hợp lệ theo schema.
    $system$,
    $task$
Hãy tạo narrative chi tiết cho năm hiện tại.

Mục tiêu:
- Giải thích chủ đề năm, ưu tiên, cảnh báo, và guidance.
- Tạo nội dung đủ sâu để user hiểu bức tranh lớn của năm.

Yêu cầu nội dung:
- Phải dài hơn preview năm ở màn home.
- Không viết lan man.
- Chỉ trả về JSON hợp lệ.
    $task$,
    $json$
{
  "type": "object",
  "required": ["profile", "year_context"],
  "properties": {
    "profile": { "type": "object" },
    "year_context": {
      "type": "object",
      "required": ["local_year", "personal_year"],
      "properties": {
        "local_year": { "type": "number" },
        "personal_year": { "type": "number" }
      }
    },
    "life_summary_compact": {
      "type": ["object", "null"]
    }
  }
}
    $json$::jsonb,
    $json$
{
  "type": "object",
  "required": ["headline", "summary_text", "theme_text", "priorities", "cautions", "guidance"],
  "properties": {
    "headline": { "type": "string" },
    "summary_text": { "type": "string" },
    "theme_text": { "type": "string" },
    "priorities": {
      "type": "array",
      "items": { "type": "string" }
    },
    "cautions": {
      "type": "array",
      "items": { "type": "string" }
    },
    "guidance": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
    $json$::jsonb,
    'Narrative detail cho màn Chi tiết năm nay. Cache theo year.',
    null,
    now(),
    now()
  ),
  (
    'active_phase_narrative',
    'v1',
    'vi-VN',
    'active',
    'gemini',
    'gemini-2.5-flash',
    0.40,
    1200,
    $system$
Bạn là Numverse AI narrative engine.

Nhiệm vụ của bạn là tạo nội dung detail cho màn "Chi tiết giai đoạn active".

Quy tắc bắt buộc:
- Chỉ được diễn giải từ facts được cung cấp.
- Không tự tính lại numerology.
- Phải nối được ý nghĩa của đỉnh cao active và thử thách active.
- Không dùng giọng văn định mệnh.
- Trả về JSON hợp lệ theo schema.
    $system$,
    $task$
Hãy tạo narrative chi tiết cho giai đoạn active hiện tại.

Mục tiêu:
- Giải thích peak active và challenge active đang tương tác với nhau như thế nào.
- Tạo summary rõ ràng và guidance thực tế cho giai đoạn hiện tại.

Yêu cầu nội dung:
- Không chỉ mô tả từng phần rời rạc.
- Phải thể hiện được bối cảnh chung của giai đoạn.
- Chỉ trả về JSON hợp lệ.
    $task$,
    $json$
{
  "type": "object",
  "required": ["profile", "phase_context"],
  "properties": {
    "profile": { "type": "object" },
    "phase_context": {
      "type": "object",
      "required": ["phase_key", "active_peak_number", "active_challenge_number"],
      "properties": {
        "phase_key": { "type": "string" },
        "phase_start_date": { "type": ["string", "null"] },
        "phase_end_date": { "type": ["string", "null"] },
        "active_peak_number": { "type": ["number", "null"] },
        "active_challenge_number": { "type": ["number", "null"] }
      }
    },
    "life_summary_compact": {
      "type": ["object", "null"]
    }
  }
}
    $json$::jsonb,
    $json$
{
  "type": "object",
  "required": ["headline", "summary_text", "peak_text", "challenge_text", "guidance"],
  "properties": {
    "headline": { "type": "string" },
    "summary_text": { "type": "string" },
    "peak_text": { "type": "string" },
    "challenge_text": { "type": "string" },
    "guidance": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
    $json$::jsonb,
    'Narrative detail cho màn Chi tiết giai đoạn active. Cache theo phase key.',
    null,
    now(),
    now()
  ),
  (
    'compatibility_narrative',
    'v1',
    'vi-VN',
    'active',
    'gemini',
    'gemini-2.5-flash',
    0.35,
    1200,
    $system$
Bạn là Numverse AI narrative engine.

Nhiệm vụ của bạn là diễn giải sự tương hợp giữa hai hồ sơ numerology theo cách cân bằng, thực tế, dễ hiểu.

Quy tắc bắt buộc:
- Chỉ được diễn giải từ facts được cung cấp.
- Không phán xét quan hệ là tốt hay xấu tuyệt đối.
- Không tạo kết luận định mệnh.
- Không tự tính thêm chỉ số numerology.
- Trả về JSON hợp lệ theo schema.
    $system$,
    $task$
Hãy tạo narrative tương hợp cho tab "Tương hợp".

Mục tiêu:
- Tạo summary tổng quan.
- Chỉ ra strengths, tensions, và guidance có tính ứng dụng.
- Viết theo hướng giúp người dùng hiểu cách kết nối tốt hơn, không phải chấm điểm phán xử.

Yêu cầu nội dung:
- strengths nên là các vùng dễ hòa hợp.
- tensions nên là các vùng dễ lệch nhịp hoặc hiểu sai nhau.
- guidance nên là các gợi ý hành động hoặc giao tiếp cụ thể.
- compact_summary phải ngắn gọn để có thể tái sử dụng ở các flow khác nếu cần.
- Chỉ trả về JSON hợp lệ.
    $task$,
    $json$
{
  "type": "object",
  "required": [
    "primary_profile",
    "target_profile",
    "primary_facts",
    "target_facts",
    "compatibility_structure"
  ],
  "properties": {
    "primary_profile": { "type": "object" },
    "target_profile": { "type": "object" },
    "primary_facts": { "type": "object" },
    "target_facts": { "type": "object" },
    "compatibility_structure": { "type": "object" },
    "primary_life_summary_compact": { "type": ["object", "null"] },
    "target_life_summary_compact": { "type": ["object", "null"] }
  }
}
    $json$::jsonb,
    $json$
{
  "type": "object",
  "required": ["summary", "strengths", "tensions", "guidance", "compact_summary"],
  "properties": {
    "summary": { "type": "string" },
    "strengths": {
      "type": "array",
      "items": { "type": "string" }
    },
    "tensions": {
      "type": "array",
      "items": { "type": "string" }
    },
    "guidance": {
      "type": "array",
      "items": { "type": "string" }
    },
    "compact_summary": { "type": "string" }
  }
}
    $json$::jsonb,
    'Narrative tương hợp giữa 2 profile. Dùng cho preview và full detail của tab Tương hợp.',
    null,
    now(),
    now()
  ),
  (
    'numai_chat_reply',
    'v1',
    'vi-VN',
    'active',
    'gemini',
    'gemini-2.5-flash',
    0.45,
    700,
    $system$
Bạn là Numverse AI assistant trong tab NumAI.

Nhiệm vụ của bạn là trả lời câu hỏi của người dùng dựa trên hồ sơ numerology và mạch hội thoại gần nhất.

Quy tắc bắt buộc:
- Chỉ được dùng các facts có trong context.
- Không tự tính lại numerology.
- Không bịa thêm daily facts hoặc compatibility facts nếu context không có.
- Không trở thành therapist, bác sĩ, luật sư, hay cố vấn tài chính.
- Không khẳng định tuyệt đối.
- Trả lời ngắn, rõ, bám đúng câu hỏi hiện tại.
- Trả về JSON hợp lệ.
    $system$,
    $task$
Hãy tạo câu trả lời cho tab "NumAI".

Mục tiêu:
- Trả lời đúng câu hỏi của user dựa trên thread_summary, recent_messages, active_profile, snapshot_facts, user_question, context_type.
- Nếu user hỏi rộng, hãy trả lời gọn trước rồi gợi ý 2-3 câu hỏi tiếp theo.
- Nếu context_type là today hoặc compatibility nhưng context hiện chưa có dữ liệu chuyên biệt, hãy trả lời dựa trên snapshot_facts và nói theo hướng thận trọng.

Yêu cầu nội dung:
- answer nên súc tích, đúng trọng tâm.
- referenced_sections nên chỉ ra vùng facts đã dùng, ví dụ: core_numbers.life_path, matrix_aspects.physical_axis.
- follow_up_suggestions nên là các câu hỏi tiếp theo thực sự hữu ích.
- Chỉ trả về JSON hợp lệ.
    $task$,
    $json$
{
  "type": "object",
  "required": [
    "thread_summary",
    "recent_messages",
    "active_profile",
    "snapshot_facts",
    "user_question",
    "context_type"
  ],
  "properties": {
    "thread_summary": {
      "type": ["object", "null"]
    },
    "recent_messages": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["role", "text"],
        "properties": {
          "role": { "type": "string" },
          "text": { "type": "string" }
        }
      }
    },
    "active_profile": { "type": "object" },
    "snapshot_facts": { "type": "object" },
    "user_question": { "type": "string" },
    "context_type": { "type": "string" }
  }
}
    $json$::jsonb,
    $json$
{
  "type": "object",
  "required": ["answer", "referenced_sections", "follow_up_suggestions"],
  "properties": {
    "answer": { "type": "string" },
    "referenced_sections": {
      "type": "array",
      "items": { "type": "string" }
    },
    "follow_up_suggestions": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
    $json$::jsonb,
    'Prompt cho NumAI MVP với fixed context payload. Chưa dùng intent detection và chưa inject daily_facts / compatibility_facts.',
    null,
    now(),
    now()
  )
on conflict (prompt_key, locale, version) do update
set
  status = excluded.status,
  provider = excluded.provider,
  model_name = excluded.model_name,
  temperature = excluded.temperature,
  max_output_tokens = excluded.max_output_tokens,
  system_prompt = excluded.system_prompt,
  task_prompt_template = excluded.task_prompt_template,
  context_schema_json = excluded.context_schema_json,
  output_schema_json = excluded.output_schema_json,
  notes = excluded.notes,
  updated_at = now();

commit;
