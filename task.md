# Member 3: Private Education Subsystem, task list

Working phase by phase. Branch: `feature/member3-private-education`.
Legend: `[ ]` todo, `[/]` in progress, `[x]` done.

## Phase 0: Prep  (done, committed)
- [x] Fix `test/widget_test.dart` (compiles and passes)
- [x] Add approved dependencies (`crypto`, `intl`, `flutter_localizations`, `integration_test`)
- [x] Bundle fonts (Outfit, Noto Sans Sinhala) in `assets/google_fonts/`, disable runtime fetching
- [x] Folder structure (`widgets/`, `content/`, `l10n/`), `routes.dart`, stub screens (onboarding, PIN setup, pharmacy)
- [x] Update `README.md`
- [x] Verify: `flutter test` passes; `flutter analyze` clean for new code (12 existing issues in other members' files left alone)

## Phase 1: Foundations  (done, committed)
- [x] Extend `AppTheme` tokens (maroon, primaryDark, success)
- [x] Shared widgets (PillButton, AppChip, AppTopBar, HideButton, TopicTile, ArticleRow, AppToast, AppProgressBar, PinDots, Keypad)
- [x] Storage additions (`SavedArticle`, settings box) and l10n skeleton
- [x] Content types, `ContentRepository`, seed content, validation test

## Phase 2: Privacy Lock + auth guard (done, committed)
- [x] `PinService` mock (PBKDF2) with `DEMO_PIN` seed
- [x] `SessionState` and lockout logic
- [x] `PrivacyLockScreen`

## Phase 3: Education Hub (done, committed)
- [x] Hub screen, search, Daily Health Tip, Explore Topics, Learn tab

## Phase 4: Category, Article, Save, Toast, HIDE (done)
- [x] `CategoryScreen` data-driven filter chips and article list
- [x] `ArticleScreen` pink hero illustration, two-toned title, rich blocks, village tip
- [x] Reversible offline save toggle and `AppToast` feedback
- [x] Panic `HideButton` clears navigation stack to `MainScreen` and locks session
- [x] Phase 4 acceptance flow test (Hub -> Category -> Article -> Save in 3 taps <= 4 taps)

## Phase 5: Offline Library  (done)
- [x] `OfflineLibraryScreen` (S6) with "Zero Internet Required" banner
- [x] Reactive list of saved articles (sorted newest first)
- [x] "Read Offline" pill and card tapping to open `ArticleScreen`
- [x] In-library unsave with reversible feedback
- [x] Empty state with friendly illustration and "Browse topics" button
- [x] Top bar panic `HideButton` (REQ-3.1)
- [x] Full test coverage (`offline_library_screen_test.dart` and `library_flow_test.dart`)

## Phase 6: Myth Buster  (done)
- [x] `MythBusterScreen` (S7) quiz state machine
- [x] Header progress indicator with "QUESTION N OF 5" and `AppProgressBar`
- [x] White question card with "?" badge, statement in quotes, and sub-prompt
- [x] Stacked response buttons: "It's a MYTH" and "It's a FACT"
- [x] Feedback banner with correct/incorrect badge, explanation, and "Next"
- [x] Results summary screen with score, best score persistence, "Play again", and "Back to hub"
- [x] Top bar panic `HideButton` (REQ-3.1)
- [x] Full test coverage (`myth_buster_screen_test.dart` and `quiz_flow_test.dart`)

## Phase 7: Offline hardening, i18n, accessibility  (done)
- [x] Verified zero external network calls; fonts bundled in `assets/google_fonts/`, runtime fetching disabled
- [x] Verified 100% offline data flow via `BundledRepository` and Hive
- [x] Sinhala i18n parity verified across all screens with dynamic language switching
- [x] Accessibility audit: Semantics on all controls, 1.5x large text scaling tested without overflow, reduced motion verified
- [x] Full automated test suite in `accessibility_and_offline_test.dart`

## Phase 8: Test instrumentation  (done)
- [x] `--dart-define=TEST_MODE=true` local `MetricsService` (records `lock_shown`, `pin_key`, `pin_error`, `unlocked`, `nav`, `article_open`, `save_offline`, `toast_shown`, `hide_tap`, `hide_done`)
- [x] In-memory local computation of metrics: time-on-task, tap count, post-unlock tap count, wrong PIN attempts, HIDE latency (<2s), task success
- [x] `TestModeOverlay` with draggable status pill, live tap counter, bottom sheet metrics dashboard, session reset, and JSON export to clipboard
- [x] Complete Think-Aloud user testing script and observation sheet in `docs/user-testing.md`
- [x] Zero PII, zero external network requests
- [x] Automated unit and widget tests in `test/services/metrics_service_test.dart` and `test/widgets/test_mode_overlay_test.dart`

## Phase 10: Hand-off  (done)
- [x] `docs/integration.md`: screens/routes, Hive boxes and type ids, `PinService` and `ContentRepository` contracts, integration points for Members 1, 2, and 4, and stable article IDs for deep-linking

