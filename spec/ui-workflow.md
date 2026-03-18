## [App Shell & Routing]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/utils/app_pages.dart

### 1. Description
Goal: Mirror web-version route map on Flutter mobile with GetX.
Features:
- Full-screen entry flow: `splash -> welcome -> login -> onboarding -> main`.
- Tab shell: `today`, `reading`, `compatibility`, `numai`, `profile`.
- Detail routes mapped 1:1 with web paths (`today-detail`, `month-detail`, `chart-matrix`, `numai-chat`, ...).

### 2. UI Structure
- Root shell: `MainPage` (`lib/src/ui/main/main_page.dart`)
- Bottom nav: `AppBottomNavBar`
- Route setup: `AppPages.pages`

### 3. User Flow & Logic
1) App opens on `SplashPage`.
2) First launch goes to `WelcomePage`, next launches go to `MainPage`.
3) Login/guest path goes through onboarding if no profile exists.
4) Tab routes can be opened directly (`/reading`, `/profile`, ...) and auto-select the tab index.
5) Detail pages push as full-screen routes with dedicated bindings.

### 4. Key Dependencies
- GetX (`GetMaterialApp`, `GetPage`, `Bindings`)
- `MainNavigationCubit` for active tab selection.

### 5. Notes & Known Issues (Optional)
- Current implementation uses full-screen detail pages (bottom nav hidden while in details).

## [Session State]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/main/interactor

### 1. Description
Goal: Replace web React contexts (`auth/profiles/soul points/guest interaction`) with Flutter Cubit + repository.
Features:
- Auth state
- Profile list and current profile
- Soul points, streak, daily check-in
- Guest interaction counting

### 2. UI Structure
- `MainSessionCubit`
- `MainSessionState`
- `AppSessionRepository` + `LocalAppSessionRepository`

### 3. User Flow & Logic
1) `MainSessionCubit.initialize()` loads persisted snapshot from shared preferences.
2) Login updates auth fields and persists snapshot.
3) Onboarding adds first profile and sets current profile.
4) Today check-in updates streak/soul points/daily earning.
5) Guest interaction API is exposed for future gating prompts.

### 4. Key Dependencies
- `shared_preferences`
- `equatable`
- GetX DI in `MainBinding`

### 5. Notes & Known Issues (Optional)
- Session errors currently map to a generic `state_error_*` UI state.

## [Localization]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/locale

### 1. Description
Goal: Enforce GetX localization for all new user-facing text.
Features:
- Keys split by module (`common`, `main`, `today`, `pages`)
- Language maps for `vi_VN`, `en_US`, `ja_JP`

### 2. UI Structure
- Keys: `lib/src/locale/keys/*.dart`
- Aggregator: `lib/src/locale/locale_key.dart`
- Language modules: `en/*`, `ja/*`, `vi/*`
- Aggregators: `lang_en.dart`, `lang_ja.dart`, `lang_vi.dart`

### 3. User Flow & Logic
1) App boots with `vi_VN` default locale.
2) All labels in converted screens use `.tr` from `LocaleKey` constants.

### 4. Key Dependencies
- GetX translations (`TranslationManager`)

### 5. Notes & Known Issues (Optional)
- Some deep-content narrative strings are still simplified compared with full web copy.

## [Today Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/today

### 1. Description
Goal: Convert web `today.tsx` experience to Flutter with dual tabs and mystical visual style.
Features:
- Time-based greeting header + profile avatar switcher
- Universal vs Personal tab
- Soul points + streak + check-in progress
- Free discovery cards (`universal-day`, `lucky-number`, `daily-message`, `angel-numbers`, `number-library`)
- Personal quick insights, action guidance, and context cards (`month`, `year`)

### 2. UI Structure
- `today_page.dart`
- Components:
  - `components/today_header.dart`
  - `components/today_tab_switch.dart`
  - `components/today_universal_content.dart`
  - `components/today_personal_content.dart`
- Interactor: `TodayBloc`

### 3. User Flow & Logic
1) User opens Today tab.
2) If profile exists, user can toggle Universal/Personal content.
3) Universal tab:
- View soul points, streak progress, daily check-in reward milestones, and daily earning cap.
- Tap free-feature cards to navigate to detail pages.
4) Personal tab:
- View hero summary (energy/rhythm), do/avoid action card, and month/year context cards.
- Tap CTA/context cards to open corresponding detail pages.
5) Check-in grants soul points and updates streak.

### 4. Key Dependencies
- `MainSessionCubit`
- `NumerologyHelper`

### 5. Notes & Known Issues (Optional)
- Home visuals follow Figma make page with animated elements (pulse, float, shimmer, sweep).

## [Universal Day Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/universal_day

### 1. Description
Goal: Match Figma `/universal-day` detail page with sticky header, mystical number focus, and explanatory guidance cards.
Features:
- Sticky glass header with back action.
- Date/energy summary card.
- Universal number hero orb with pulse animation and keyword chips.
- Meaning card, advice card, and additional tips card.
- Bottom info note explaining global applicability.

### 2. UI Structure
- `universal_day_page.dart` (composition only)
- Components:
  - `components/universal_day_header.dart`
  - `components/universal_day_content.dart`
- Interactor:
  - `interactor/universal_day_bloc.dart`
  - `interactor/universal_day_state.dart`

### 3. User Flow & Logic
1) User opens `/universal-day` from Today free features.
2) `UniversalDayBloc` computes:
- universal day number (reduced to 1-9),
- localized date text,
- number title/keywords,
- meaning/advice copy for the day number.
3) UI renders all sections in a scroll view under sticky header.
4) Back action returns to previous screen (fallback to main route).

### 4. Key Dependencies
- `intl` (`DateFormat`) for date rendering.
- `GetX` for DI + navigation.
- Shared mystical widgets/tokens (`AppMysticalScaffold`, `AppMysticalCard`, `AppColors`, `AppStyles`).

### 5. Notes & Known Issues (Optional)
- Meaning/advice data currently maps by number (1-9) to keep deterministic parity with current Figma flow.

## [Lucky Number Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/lucky_number

### 1. Description
Goal: Match Figma `/lucky-number` page with mystical lucky-number hero, meaning breakdown, and action-oriented usage tips.
Features:
- Sticky glass header with back action.
- Date line at top.
- Lucky number display card with star pulse and ping orb animation.
- Meaning card showing number title/description and keyword chips.
- Usage card with 4 actionable bullet tips.
- Bottom note about daily-energy basis.

### 2. UI Structure
- `lucky_number_page.dart` (composition only)
- Components:
  - `components/lucky_number_header.dart`
  - `components/lucky_number_content.dart`
- Interactor:
  - `interactor/lucky_number_bloc.dart`
  - `interactor/lucky_number_state.dart`

### 3. User Flow & Logic
1) User opens `/lucky-number` from Today free features.
2) `LuckyNumberBloc` computes:
- lucky number from current day seed,
- localized date text,
- number meaning (title, description, keywords).
3) UI renders hero + content cards in a scroll view under sticky header.
4) Back action returns to previous route (fallback to main route).

### 4. Key Dependencies
- `intl` (`DateFormat`) for date rendering.
- `GetX` for DI + navigation.
- Shared mystical widgets/tokens (`AppMysticalScaffold`, `AppMysticalCard`, `AppColors`, `AppStyles`).

### 5. Notes & Known Issues (Optional)
- Meaning dataset currently follows local map for deterministic parity with web version.

## [Daily Message Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/daily_message

### 1. Description
Goal: Match Figma `/daily-message` page with a guidance-focused hero card and supporting action/reflection/practice sections.
Features:
- Sticky glass header with back action.
- Date line at top.
- Animated message hero (chat orb pulse, sparkle divider, universal day badge).
- Action card + reflection card.
- Practice tips card with bullet checklist.
- Bottom note about daily message refresh cycle.

### 2. UI Structure
- `daily_message_page.dart` (composition only)
- Components:
  - `components/daily_message_header.dart`
  - `components/daily_message_content.dart`
- Interactor:
  - `interactor/daily_message_bloc.dart`
  - `interactor/daily_message_state.dart`

### 3. User Flow & Logic
1) User opens `/daily-message` from Today free features.
2) `DailyMessageBloc` computes:
- universal day number (reduced to 1-9),
- localized date text,
- message template (main/sub/action hint) mapped by day number and rotated by day-of-year index.
3) UI renders hero + support sections in a scroll view under sticky header.
4) Back action returns to previous route (fallback to main route).

### 4. Key Dependencies
- `intl` (`DateFormat`) for date rendering.
- `GetX` for DI + navigation.
- `flutter_bloc` (`Cubit`, `BlocBuilder`) for deterministic state rendering.
- Shared mystical widgets/tokens (`AppMysticalScaffold`, `AppMysticalCard`, `AppColors`, `AppStyles`).

### 5. Notes & Known Issues (Optional)
- Message templates are embedded local data; selection follows `dayOfYear % templateCount` to mirror Figma Make behavior.

## [Angel Numbers Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/angel_numbers

### 1. Description
Goal: Match Figma `/angel-numbers` page with lookup-first UX, quick popular chips, and mystical result cards.
Features:
- Sticky glass header with back action.
- Intro card describing Angel Numbers context.
- Search box with numeric input + search action.
- Popular number chips (`111`..`1212`) for quick lookup.
- Animated result stack (number orb, meaning, guidance).
- Fallback tips card before first lookup.

### 2. UI Structure
- `angel_numbers_page.dart` (composition only)
- Components:
  - `components/angel_numbers_header.dart`
  - `components/angel_numbers_content.dart`
- Interactor:
  - `interactor/angel_numbers_bloc.dart`
  - `interactor/angel_numbers_state.dart`

### 3. User Flow & Logic
1) User opens `/angel-numbers` from Today free features.
2) User can:
- type a number manually then tap search, or
- tap a popular number chip.
3) `AngelNumbersBloc` validates numeric input and resolves content by:
- known predefined mappings (`111`, `222`, ..., `1212`), or
- generated fallback meaning for other numeric strings.
4) UI transitions from tips state to animated result section.
5) Back action returns to previous route (fallback to main route).

### 4. Key Dependencies
- `GetX` for DI + navigation.
- `flutter_bloc` (`Cubit`, `BlocBuilder`) for predictable lookup state.
- Shared mystical tokens/widgets (`AppMysticalScaffold`, `AppMysticalCard`, `AppColors`, `AppStyles`).

### 5. Notes & Known Issues (Optional)
- Result content is currently local static/generative data (no remote API call).

## [Number Library Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/number_library

### 1. Description
Goal: Match Figma `/number-library` page with sticky number-picker UX, expandable theory cards, and detailed number interpretation.
Features:
- Sticky glass header with back action.
- Compact intro card.
- Expand/collapse explanation cards:
- basic numbers (1-9),
- master numbers (11/22/33).
- Sticky selector card:
- basic number grid (1-9),
- master number grid (11/22/33).
- Smooth auto-scroll to details after selection.
- Selected detail cards:
- number hero + title + keyword chips,
- meaning & energy section,
- appearance/use section.

### 2. UI Structure
- `number_library_page.dart` (composition only)
- Components:
  - `components/number_library_header.dart`
  - `components/number_library_content.dart`
- Interactor:
  - `interactor/number_library_bloc.dart`
  - `interactor/number_library_state.dart`

### 3. User Flow & Logic
1) User opens `/number-library` from Today free features.
2) User can open explanatory sections for base numbers and master numbers.
3) User picks a number in sticky selector.
4) `NumberLibraryBloc` updates selected number and resolved meaning data.
5) UI animates/scrolls to detail section and renders full interpretation cards.
6) Back action returns to previous route (fallback to main route).

### 4. Key Dependencies
- `GetX` for DI + navigation.
- `flutter_bloc` (`Cubit`, `BlocBuilder`) for predictable expandable/selection state.
- `NumerologyHelper.meaningByNumber` as local meaning source.
- Shared mystical widgets/tokens (`AppMysticalScaffold`, `AppMysticalCard`, `AppColors`, `AppStyles`).

### 5. Notes & Known Issues (Optional)
- Number meanings are local static data (no remote API call).

## [Secondary Features]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/*

### 1. Description
Goal: Provide 1:1 navigable mobile modules for all web routes.
Features:
- `reading`, `compatibility`, `comparison-result`, `numai`, `numai-chat`, `profile`.
- Detail modules: `core-numbers`, `chart-matrix`, `life-path`, `personal-portrait`, `today-detail`, `month-detail`, `year-detail`, `phase-detail`, `my-profile`, `saved-profiles`, `subscription`, `settings`, `notifications`, `privacy`, `help`.

### 2. UI Structure
- Each feature has `binding/`, `interactor/`, `components/`, and `<feature>_page.dart`.

### 3. User Flow & Logic
1) Tab entries provide high-level navigation and CTA.
2) Detail pages use `AppSimplePage` composition for consistent UI and state readiness.
3) NumAI chat keeps a local conversational loop to mirror chat flow.

### 4. Key Dependencies
- GetX routing/bindings
- Shared UI widgets (`AppMysticalCard`, `AppSimplePage`, `AppPrimaryButton`)

### 5. Notes & Known Issues (Optional)
- Several deep analysis pages are currently scaffolded with concise sections and can be expanded with full narrative blocks from web copy/API.

## [Reading Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/reading

### 1. Description
Goal: Match Figma `/reading` hub page with profile summary card, locked overlays, and feature entry cards.
Features:
- Reading title/subtitle and profile summary card.
- Core metrics shown on summary card: Life Path, Mission, Soul Urge.
- Locked overlays for 4 reading modules when user has no profile.
- Inline profile input dialog (name + birth date) to unlock modules.

### 2. UI Structure
- `reading_page.dart`
- Components:
  - `components/reading_content.dart`
  - `components/reading_profile_dialog.dart`
- Interactor:
  - `interactor/reading_bloc.dart`
  - `interactor/reading_state.dart`

### 3. User Flow & Logic
1) User opens Reading tab.
2) If profile exists:
- summary card shows profile initials, name, birth date, and 3 core numbers,
- feature cards navigate to `/core-numbers`, `/chart-matrix`, `/life-path`, `/personal-portrait`.
3) If profile does not exist:
- summary card shows placeholders,
- lock overlay intercepts card tap and opens profile dialog.
4) User submits dialog -> `MainSessionCubit.addProfile()` -> cards unlock immediately.

### 4. Key Dependencies
- `MainSessionCubit` / `MainSessionState`
- `ReadingBloc`
- `NumerologyHelper`

### 5. Notes & Known Issues (Optional)
- Lock UX mirrors web flow but uses Flutter `Dialog` for profile creation.

## [Core Numbers Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/core_numbers

### 1. Description
Goal: Match Figma `/core-numbers` page with intro, summary narrative, and 4 detailed number cards.
Features:
- Sticky glass header and mystical background.
- Intro card explaining 4 foundational numbers.
- Summary card combining Life Path, Soul Urge, Personality, Mission.
- Four detail cards with number orb, intro, interpretation, and keyword chips.

### 2. UI Structure
- `core_numbers_page.dart`
- Components:
  - `components/core_numbers_header.dart`
  - `components/core_numbers_content.dart`
- Interactor:
  - `interactor/core_numbers_bloc.dart`
  - `interactor/core_numbers_state.dart`

### 3. User Flow & Logic
1) User opens `/core-numbers` from Reading.
2) `CoreNumbersBloc.syncProfile()` computes numbers from current profile:
- life path,
- soul urge,
- personality,
- mission.
3) Content cards render mapped interpretations from local numerology data.
4) If no profile, screen renders locked empty-state CTA to onboarding.

### 4. Key Dependencies
- `MainSessionCubit`
- `NumerologyHelper` + `NumerologyReadingData`
- `CoreNumbersBloc`

### 5. Notes & Known Issues (Optional)
- Uses local content dataset for deterministic rendering parity with design flow.

## [Chart Matrix Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/chart_matrix

### 1. Description
Goal: Match Figma `/chart-matrix` with two collapsible blocks: Birth Chart and Name Chart.
Features:
- Sticky header with back navigation.
- Birth chart section (expand/collapse):
- 3x3 Pythagorean matrix,
- strengths and missing lessons,
- mental/emotional/physical axis bars,
- missing numbers panel.
- Name chart section (expand/collapse):
- 3x3 matrix by name,
- dominant numbers,
- present/missing number analysis,
- 3-axis mini bars.

### 2. UI Structure
- `chart_matrix_page.dart`
- Components:
  - `components/chart_matrix_header.dart`
  - `components/chart_matrix_content.dart`
- Interactor:
  - `interactor/chart_matrix_bloc.dart`
  - `interactor/chart_matrix_state.dart`

### 3. User Flow & Logic
1) User opens `/chart-matrix`.
2) `ChartMatrixBloc.syncProfile()` computes:
- birth chart grid + axes + arrows,
- name chart grid + axes + dominant numbers.
3) User toggles section expansion for Birth and Name charts.
4) Cards update from deterministic chart math and local meaning dataset.

### 4. Key Dependencies
- `MainSessionCubit`
- `NumerologyHelper` + `BirthChartDataSet`
- `ChartMatrixBloc`

### 5. Notes & Known Issues (Optional)
- Arrow patterns are computed and stored in state for future section expansion.

## [Life Path Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/life_path

### 1. Description
Goal: Present Life Path in a compact stage chart so users quickly identify current phase and open details per pinnacle/challenge.
Features:
- Intro card with current age context.
- Radar-style quadrilateral chart:
  - 4 vertices representing 4 phases.
  - Single merged stage chart with semantic titles (for example `Đỉnh trưởng thành`) and age labels (`0 - 34 tuổi`).
- Status coloring per vertex/edge (passed / active / future).
- Tap each stage vertex to open a combined detail route.
- Rendering stack uses `fl_chart` (`RadarChart`) for chart geometry, tick/grid, and touch handling.
- Visual style: app-primary palette, diamond polygon fill, central circular badge (icon-only), and highlighted vertex markers.
- Vertex labels are clamped to chart bounds so title/age do not overflow on narrow screens.
- Dynamic detail page renders both `Đỉnh cuộc đời` and `Đỉnh thử thách` sections for the selected stage.

### 2. UI Structure
- `life_path_page.dart`
- Components:
  - `components/life_path_header.dart`
  - `components/life_path_content.dart`
- Interactor:
  - `interactor/life_path_bloc.dart`
  - `interactor/life_path_state.dart`
- Detail route reused:
  - `/phase-detail` with `PhaseDetailStageArgs` (legacy `PhaseDetailArgs` still supported)
  - `lib/src/ui/phase_detail/phase_detail_page.dart`

### 3. User Flow & Logic
1) User opens `/life-path`.
2) `LifePathBloc.syncProfile()` computes current age +
- 4 Pinnacles,
- 4 Challenges,
with period and status.
3) UI merges pinnacle/challenge data by stage index and renders 1 radar-like quadrilateral chart.
4) Active vertex is visually highlighted.
5) User taps any stage vertex.
6) App pushes `/phase-detail` and passes stage metadata with both pinnacle/challenge content.
7) Detail screen shows full interpretation for both sections in one page.

### 4. Key Dependencies
- `MainSessionCubit`
- `NumerologyHelper` + `NumerologyReadingData`
- `LifePathBloc`

### 5. Notes & Known Issues (Optional)
- Main Life Path screen is intentionally short-text and chart-first; long narrative is moved to detail route.

## [Personal Portrait Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/personal_portrait

### 1. Description
Goal: Match Figma `/personal-portrait` with multi-section personality report.
Features:
- Intro card.
- 4 aspect cards:
- personality,
- communication,
- relationship,
- career.
- Trait bars (score/10) for each aspect.
- Strengths card, Growth Areas card, Career recommendation grid, closing quote panel.

### 2. UI Structure
- `personal_portrait_page.dart`
- Components:
  - `components/personal_portrait_header.dart`
  - `components/personal_portrait_content.dart`
- Interactor:
  - `interactor/personal_portrait_bloc.dart`
  - `interactor/personal_portrait_state.dart`

### 3. User Flow & Logic
1) User opens `/personal-portrait`.
2) `PersonalPortraitBloc` serves static structured portrait state.
3) UI renders sections in order with score bars and recommendation lists.

### 4. Key Dependencies
- `PersonalPortraitBloc`
- Shared mystical tokens/widgets (`AppColors`, `AppStyles`, gradients, glow cards).

### 5. Notes & Known Issues (Optional)
- Current portrait report content is static, prepared to be replaced by profile-driven personalization later.

## [Compatibility Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/compatibility

### 1. Description
Goal: Match Figma `/compatibility` with profile-selection workflow, soul-point gating, add-profile modal flow, and history replay.
Features:
- Header + subtitle in tab context (no back button).
- Current profile card with life path summary.
- Compare-profile list with selected state.
- Add compare-profile modal (name/relation/birth date).
- Soul-point summary card + compare CTA with cost badge.
- If points are insufficient, compare button switches to inline CTA text:
`Cần thêm @points point để so sánh. Kiếm thêm`.
- Compatibility history list under compare CTA.
- Guard flow:
- no own profile -> unlock profile dialog,
- insufficient soul points -> insufficient modal,
- success -> deduct points, persist history item, and navigate to comparison result.

### 2. UI Structure
- `compatibility_page.dart`
- Components:
  - `components/compatibility_content.dart`
  - `components/compatibility_add_profile_dialog.dart`
  - `components/compatibility_profile_input_dialog.dart`
  - `components/compatibility_insufficient_points_dialog.dart`
- Interactor:
  - `interactor/compatibility_bloc.dart`
  - `interactor/compatibility_state.dart`

### 3. User Flow & Logic
1) User opens Compatibility tab.
2) User adds one or more compare profiles.
3) User selects target profile.
4) On compare tap:
- If no own profile -> profile unlock dialog appears.
- If soul points < 20 -> insufficient modal appears.
- Else deduct 20 soul points, create/save a compatibility history item, and navigate to `/comparison-result` with history payload.
5) When soul points are insufficient, tapping the compare button CTA opens
`ProfileSoulPointsActionsDialog` (watch ad / buy points).
6) User can tap any history item to reopen comparison result in view-only mode (no additional point deduction).

### 4. Key Dependencies
- `MainSessionCubit` for current profile + soul points + history persistence.
- `NumerologyHelper` for life path calculation.
- `CompatibilityBloc` for compare-profile state.

### 5. Notes & Known Issues (Optional)
- Compatibility history is persisted in local snapshot and synced to Supabase via RPC when cloud session is available.

## [Comparison Result Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/comparison_result

### 1. Description
Goal: Match Figma `/comparison-result/:id` with full-screen compatibility report and sectioned analysis cards.
Features:
- Glass header with back action to previous stack.
- Animated overall score hero with status label.
- Side-by-side identity badges for both persons.
- Aspect cards (core/communication/soul/personality) with score + progress bars.
- Strengths, challenges, and advice cards.
- Closing quote card.

### 2. UI Structure
- `comparison_result_page.dart`
- Components:
  - `components/comparison_result_header.dart`
  - `components/comparison_result_content.dart`
- Interactor:
  - `interactor/comparison_result_bloc.dart`
  - `interactor/comparison_result_state.dart`

### 3. User Flow & Logic
1) Page receives either:
- selected compare profile payload (fresh compare flow), or
- saved compatibility history payload (view-only flow).
2) `ComparisonResultBloc`:
- `load()` combines current session profile + selected compare profile and computes pair scores.
- `loadFromHistory()` restores pair scores directly from persisted history item.
3) UI renders:
- overall score/status,
- detailed aspect cards,
- static narrative guidance blocks.
4) Back action returns to previous route (fallback to main route).

### 4. Key Dependencies
- `MainSessionCubit` (current profile context)
- `NumerologyHelper` (life path/soul/personality/expression metrics)
- `ComparisonResultBloc` for deterministic scoring state

### 5. Notes & Known Issues (Optional)
- Narrative text is localized static copy; score values are computed dynamically from profile metrics.

## [NumAI Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/numai

### 1. Description
Goal: Match Figma `/numai` with AI entry experience, soul-point visibility, and quick question routing.
Features:
- Hero card with animated glow/sparkle motion.
- Soul points card (current balance + message cost + earning hint).
- "Bạn có thể hỏi về" topic list.
- Suggested question cards with profile-required badge.
- Start-chat CTA with disabled state when points are insufficient.
- Insufficient-points hint includes `Nhận thêm ngay` CTA to open earn/buy dialog.

### 2. UI Structure
- `numai_page.dart` (composition + session state wiring)
- Components:
  - `components/numai_header.dart`
  - `components/numai_hero_card.dart`
  - `components/numai_soul_points_card.dart`
  - `components/numai_topics_card.dart`
  - `components/numai_suggested_questions.dart`
  - `components/numai_start_chat_section.dart`
- Interactor:
  - `interactor/numai_bloc.dart`
  - `interactor/numai_state.dart`

### 3. User Flow & Logic
1) User opens NumAI tab.
2) Page reads `MainSessionCubit` for current `soulPoints` and profile availability.
3) User can:
- tap a suggested question -> navigate to `/numai-chat` with `initialMessage` argument,
- tap start-chat CTA -> navigate to `/numai-chat`.
4) If points < 3, CTA becomes disabled and warning text appears.
5) Tapping `Nhận thêm ngay` opens `ProfileSoulPointsActionsDialog` (watch ad / buy points).

### 4. Key Dependencies
- `MainSessionCubit` for session/profile/soul points.
- `NumAiBloc` for static screen-state model.
- GetX route argument passing to chat page.

### 5. Notes & Known Issues (Optional)
- Topic/suggestion content is localized and currently static, prepared for server-driven prompt sets later.

## [NumAI Chat Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/numai_chat

### 1. Description
Goal: Match Figma `/numai-chat` with conversational UX, soul-point deduction, and profile-gated personal replies.
Features:
- Sticky header with back action and live soul-point chip.
- Empty-state hero + quick suggestion chips.
- User/assistant bubbles with timestamp.
- Loading bubble ("Đang suy nghĩ...").
- Input bar with clear/send actions, insufficient-points warning, and per-message cost note.
- Profile-action button on assistant responses that require personal profile context.

### 2. UI Structure
- `numai_chat_page.dart`
- Components:
  - `components/numai_chat_header.dart`
  - `components/numai_chat_messages.dart`
  - `components/numai_chat_input_bar.dart`
- Interactor:
  - `interactor/numai_chat_bloc.dart`
  - `interactor/numai_chat_state.dart`

### 3. User Flow & Logic
1) User enters chat (optionally with `initialMessage` from route args).
2) On send:
- check cost and deduct `3` Soul Points through `MainSessionCubit`,
- append user message,
- show loading state,
- append assistant response (mocked local logic).
3) If question is personal and user has no profile:
- assistant returns profile-required response + action button,
- user taps action -> profile dialog opens,
- after successful profile creation, pending question receives personalized follow-up response.
4) If insufficient points, send is blocked and `ProfileSoulPointsActionsDialog` is shown to let user watch ad or buy points.

### 4. Key Dependencies
- `MainSessionCubit` for point deduction and profile creation.
- `CompatibilityProfileInputDialog` reused for profile unlock input.
- `NumAiChatBloc` for message timeline state and personal/universal question classification.

### 5. Notes & Known Issues (Optional)
- Assistant responses are currently local mock text for parity/prototyping and can be replaced by real API integration later.

## [Profile Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/profile

### 1. Description
Goal: Match Figma `/profile` with personal identity card, account warnings, utility menu, and authenticated logout action.
Features:
- Header title “Tôi”.
- Subtitle switches by auth state: normal subtitle vs “chưa được sao lưu” for guest with profile.
- Identity card with avatar initial, name/birth date, Soul Points badge.
- Menu entries: Settings, Privacy, Help.
- Logout action card shown only when authenticated.

### 2. UI Structure
- `profile_page.dart`
- Components:
  - `components/profile_header.dart`
  - `components/profile_identity_card.dart`
  - `components/profile_menu_section.dart`
  - `components/profile_menu_card.dart`
  - `components/profile_logout_card.dart`
- Interactor:
  - `interactor/profile_bloc.dart`
  - `interactor/profile_state.dart`

### 3. User Flow & Logic
1) User opens Profile tab.
2) If user has profile but not registered, header subtitle shows backup warning.
3) Tapping identity card:
- no profile -> open profile input dialog and create profile,
- has profile but not authenticated -> navigate to Login,
- has profile + authenticated -> open My Profile route.
4) Menu cards navigate to `/settings`, `/privacy`, `/help`.
5) Authenticated users can logout via confirmation dialog and return to main route.

### 4. Key Dependencies
- `MainSessionCubit` (profile/auth/soul points/logout).
- `ProfileBloc` for menu model state.
- `CompatibilityProfileInputDialog` reused for profile creation flow.

### 5. Notes & Known Issues (Optional)
- Profile warning flow mirrors Figma’s guest-data-risk messaging; auth dialog from web is replaced by app login route.

## [Settings Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/settings

### 1. Description
Goal: Match Figma `/settings` with sticky header and two grouped preference cards.
Features:
- Header with back action.
- Appearance card: theme switch (light/dark), language selector.
- Sound & notifications card: sound effects toggle, push notifications toggle.

### 2. UI Structure
- `settings_page.dart`
- Components:
  - `components/settings_header.dart`
  - `components/settings_appearance_card.dart`
  - `components/settings_sound_card.dart`
- Interactor:
  - `interactor/settings_bloc.dart`
  - `interactor/settings_state.dart`

### 3. User Flow & Logic
1) User opens `/settings` from Profile menu.
2) Theme buttons update local settings state.
3) Language dropdown updates local settings state and applies `Get.updateLocale`.
4) Sound/notification switches update local settings state.
5) Back action pops route (fallback to main route).

### 4. Key Dependencies
- `SettingsBloc` state for toggle/select interactions.
- `TranslationManager.appLocales` for runtime locale switching.

### 5. Notes & Known Issues (Optional)
- Theme switch currently controls settings state only; global app theme wiring can be connected later if needed.

## [Privacy Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/privacy

### 1. Description
Goal: Match Figma `/privacy` with privacy overview and legal document list layout.
Features:
- Header with back action.
- Security overview card.
- Legal documents list card (privacy policy, terms, data security policy).

### 2. UI Structure
- `privacy_page.dart`
- Components:
  - `components/privacy_header.dart`
  - `components/privacy_overview_card.dart`
  - `components/privacy_documents_card.dart`
- Interactor:
  - `interactor/privacy_bloc.dart`
  - `interactor/privacy_state.dart`

### 3. User Flow & Logic
1) User opens `/privacy` from Profile menu.
2) Page reads document items from `PrivacyState`.
3) User can review legal-document entries with latest update label.
4) Back action pops route (fallback to main route).

### 4. Key Dependencies
- `PrivacyBloc` for deterministic document list state.

### 5. Notes & Known Issues (Optional)
- Document entries are static for now and prepared for future deeplink/webview actions.

## [Help Feature]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/help

### 1. Description
Goal: Match Figma `/help` with support quick-actions and FAQ accordion behavior.
Features:
- Header with back action.
- Support card (email + hotline).
- FAQ section with expandable answers and animated arrow/size transitions.

### 2. UI Structure
- `help_page.dart`
- Components:
  - `components/help_header.dart`
  - `components/help_support_card.dart`
  - `components/help_faq_section.dart`
- Interactor:
  - `interactor/help_bloc.dart`
  - `interactor/help_state.dart`

### 3. User Flow & Logic
1) User opens `/help` from Profile menu.
2) FAQ list renders from `HelpState`.
3) Tapping a question toggles expanded answer (single expanded at a time).
4) Back action pops route (fallback to main route).

### 4. Key Dependencies
- `HelpBloc` for FAQ expansion state.

### 5. Notes & Known Issues (Optional)
- Contact actions are currently informative rows; external intents can be wired in a later iteration.

## [Profile Soul Points Actions]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/profile

### 1. Description
Goal: Add quick "Earn more" entry in profile identity card so users can watch ads or move to point purchase flow.
Features:
- CTA `Nhận thêm ->` next to current Soul Points.
- Modal with 2 options: watch ad / buy point.
- Display ad-earned progress for today and lock watch-ad option when daily limit is reached.

### 2. UI Structure
- `profile_page.dart`
- `components/profile_identity_card.dart`
- `components/profile_soul_points_actions_dialog.dart`

### 3. User Flow & Logic
1) User taps `Nhận thêm ->` on profile card.
2) Modal shows progress `earned/limit` and action options.
3) Tap watch-ad dispatches `MainSessionBloc.claimAdReward(amount, placementCode)`.
4) For cloud session, bloc queries Supabase RPC `get_ad_reward_status` first to gate daily ad quota.
5) If quota is available, bloc claims reward via Supabase RPC `grant_ad_reward` with unique request id and updates `soulPoints` from server response.
6) Tap buy-point routes to `/subscription`.

### 4. Key Dependencies
- `MainSessionBloc` ad reward state: `dailyAdEarnings`, `dailyAdLimit`.
- `CloudAccountRepository` RPC methods: `getAdRewardStatus`, `grantAdReward`.
- GetX route helper to open `AppPages.subscription`.

### 5. Notes & Known Issues (Optional)
- AdMob SDK callback hook is still required so `claimAdReward` is called only after `onUserEarnedReward`.
- `grant_ad_reward` is server-authoritative for reward amount, daily limit, and idempotency by `request_id`.

## [Subscription Point Purchase]
**Path**: /Users/uranidev/Documents/Numverse/lib/src/ui/subscription

### 1. Description
Goal: Redesign Subscription page into point top-up page.
Features:
- Trust hint card for secure checkout context.
- Current balance card with quick Soul Points snapshot.
- Point pack list with 2 options and one highlighted "best value" pack.
- Each pack includes points, price, and buy action.
- Buy action per pack and purchase success feedback.

### 2. UI Structure
- `subscription_page.dart`
- Components:
  - `components/subscription_balance_card.dart`
  - `components/subscription_point_pack_card.dart`

### 3. User Flow & Logic
1) User opens `/subscription`.
2) Page shows secure checkout hint + current Soul Points from `MainSessionBloc`.
3) User selects a preferred pack and taps buy.
4) App adds points locally and shows success snackbar.

### 4. Key Dependencies
- `MainSessionBloc.addSoulPoints`.
- Localization keys under `subscription_*`.

### 5. Notes & Known Issues (Optional)
- Current purchase flow is UI-first mock top-up and does not connect to billing gateway yet.
