# Model Registry

## AppSessionSnapshot
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/app_session_snapshot.dart`
- **Type**: UI/Domain state snapshot
- **Purpose**: Persist app-level session data (auth, profiles, soul points, check-in metrics, compatibility history).
- **Source**: Local storage (`shared_preferences`) via repository.

## UserProfile
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/user_profile.dart`
- **Type**: UI/Domain model
- **Purpose**: Represents a saved numerology profile used across Today/Profile/Compatibility flows.
- **Source**: Local user input from onboarding/profile management.

## ComparisonProfile
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/comparison_profile.dart`
- **Type**: UI/Domain model
- **Purpose**: Represents a compatibility target profile (name, relation, birth date, life path) used in Compatibility and Comparison Result flows.
- **Source**: Local user input in compatibility add-profile modal.

## CompatibilityHistoryItem
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/compatibility_history_item.dart`
- **Type**: UI/Domain model
- **Purpose**: Represents a persisted compatibility result item (pair identity + computed scores) for history listing and view-only reopening of past comparison results.
- **Source**: Computed on compare action in app, then persisted local snapshot and optionally synchronized to Supabase RPC.

## Numerology Reading Models
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/numerology_reading_models.dart`
- **Type**: UI/Domain model
- **Purpose**: Shared typed models for Reading stack (`core-numbers`, `chart-matrix`, `life-path`) including chart grids, axis scores, cycle states, and content blocks.
- **Source**: Derived from profile input (`UserProfile`) via `NumerologyHelper` local computations, and mapped content from numerology ledger repository.

## Numerology Content Models
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/numerology_content_models.dart`
- **Type**: UI/Domain model
- **Purpose**: Typed offline content models for numerology JSON assets (`universal_day`, `daily_message`, `lucky_number`, `angel_number`, `number_library`) to avoid hardcoded mapping inside BLoC files.
- **Notes**:
  - `number_library` entries include `title`, `description`, `keywords`, and `symbolism` for the Number Library detail UI.
  - Ledger content now also serves life-based reading modules via types: `life_path_number`, `expression_number`, `soul_urge_number`, `mission_number`, `birthday_matrix`, `name_matrix`, `life_pinnacle`, `life_challenge`.
- **Source**: Local static JSON assets under `/Users/uranidev/Documents/Numverse/assets/numerology/`.

## ProfileTimeLifeSnapshot
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/profile_time_life_snapshot.dart`
- **Type**: UI/Domain model
- **Purpose**: Stores per-profile time-life calculation cache metadata (`computedAt`, `refreshAt`) and daily values, so cached snapshots can be invalidated by time and removed when a profile is deleted.
- **Source**: Derived from local numerology calculations and persisted inside app session storage.

## CloudLoginResult
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/cloud_login_result.dart`
- **Type**: UI/Domain model
- **Purpose**: Encapsulates Supabase auth result for verified account login and first cloud sync handshake (`userId`, tokens, first-sync outcome).
- **Source**: Supabase Auth REST response + bootstrap RPC result.

## CloudAdRewardStatusResult
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/cloud_ad_reward_status_result.dart`
- **Type**: UI/Domain model
- **Purpose**: Encapsulates ad reward quota snapshot from cloud (`dailyLimit`, `todayEarned`, `remaining`, `canWatch`, `soulPoints`) for pre-check before showing rewarded ads.
- **Source**: Supabase RPC `get_ad_reward_status`.

## CloudAdRewardGrantResult
- **Path**: `/Users/uranidev/Documents/Numverse/lib/src/core/model/cloud_ad_reward_grant_result.dart`
- **Type**: UI/Domain model
- **Purpose**: Encapsulates server-authoritative reward grant response (`granted/idempotent`, `rewardAwarded`, `todayEarned`, `dailyLimit`, `soulPoints`) after an ad reward claim.
- **Source**: Supabase RPC `grant_ad_reward`.
