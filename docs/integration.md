# Cycle Care: Private Education Subsystem Integration Guide

**Subsystem:** Private Education Subsystem (Member 3)  
**Author:** A M S P Aththanayake (IT23184244) · **Group:** WE_05  
**Target Audience:** Member 1 (Privacy & Onboarding), Member 2 (Core Tracking), Member 4 (Healthcare Access)

---

## 1. Overview & Architecture

The Private Education Subsystem provides offline-first, culturally sensitive, bilingual (English & Sinhala) menstrual health education designed specifically for teenage girls in rural Sri Lankan schools.

### Key Architectural Pillars
1. **Zero Network Incurred (FR6 / REQ-3.2):** 100% of educational content, assets, and Google Fonts (`Outfit`, `Noto Sans Sinhala`) are bundled locally. `GoogleFonts.config.allowRuntimeFetching = false` is enforced.
2. **Privacy by Design (FR9 / REQ-3.1):** High-contrast panic **HIDE** button clears the navigation stack to `MainScreen` with zero animation latency ($<100$ ms) and locks back-stack traversal. All sensitive session data resides in-memory only.
3. **Bilingual Localization (FR8):** All screens and content models use a unified `Lang` enum (`'en'` and `'si'`) with `Localized<T>` models and ARB-backed string lookups.

---

## 2. Navigation Routes & Screens

All screens are registered or accessible via the navigation helper `AppRoutes` in [`lib/routes.dart`](file:///d:/assignments/CycleTracket/lib/routes.dart).

### Screen Map

| Screen | Class | Entry / Trigger | Guard Requirement |
| :--- | :--- | :--- | :--- |
| **Privacy Lock** | `PrivacyLockScreen` | Cold app launch (`main.dart` `home`) | None (First screen) |
| **Education Hub** | `EducationHubScreen` | Bottom Navigation Tab Index `2` (`Learn`) | Unlocked session |
| **Category List** | `CategoryScreen` | Tap topic tile on Hub (`food-diet`, `our-body`) | Unlocked session |
| **Article Reader** | `ArticleScreen` | Tap article row from category, library, or search | Unlocked session |
| **Offline Library** | `OfflineLibraryScreen` | Tap "Saved Library" tile on Hub | Unlocked session |
| **Myth Buster Quiz** | `MythBusterScreen` | Tap "Myth Buster" highlighted tile on Hub | Unlocked session |
| **Onboarding Stub** | `OnboardingStubScreen` | First-time user welcome flow (Member 1) | None |
| **PIN Setup Stub** | `PinSetupStubScreen` | First-time PIN setup (Member 1) | None |
| **Pharmacy Stub** | `PharmacyStubScreen` | Healthcare directory navigation (Member 4) | Unlocked session |

### Navigation Helper (`AppRoutes`)

Use `AppRoutes` rather than raw `Navigator` methods to ensure consistent instrumentation and stack management:

```dart
import 'package:cycle_care/routes.dart';
import 'package:cycle_care/screens/article_screen.dart';

// 1. Standard Push (records 'nav' metric event)
AppRoutes.push(context, const ArticleScreen(articleId: 'water-hydration'));

// 2. Route Replacement (cannot go back to previous screen)
AppRoutes.replace(context, const MainScreen());

// 3. Stack Clearing Reset (Used by HIDE button; zero transition animation)
AppRoutes.resetTo(context, const MainScreen());
```

---

## 3. Hive Storage Contracts & Type IDs

Hive type IDs are permanent across the shared project. The allocated registry is as follows:

| Type ID | Model Class | Hive Box | Owner | Purpose |
| :---: | :--- | :--- | :--- | :--- |
| **`0`** | `CycleEntry` | `cycle_entries` | **Member 2** | Cycle dates, flow intensity, symptoms, mood |
| **`1`** | `SavedArticle` | `saved_articles` | **Member 3** | Saved article metadata for offline reading |

### Shared Hive Boxes and Key Contracts

#### 1. `saved_articles` Box (Owner: Member 3)
- **Model:** `SavedArticle` (`lib/models/saved_article.dart`)
- **Key:** `articleId` (`String`)
- **Fields:**
  - `articleId` (`String`): Unique identifier of the article.
  - `savedAt` (`DateTime`): Timestamp when the article was saved.
- **Store Accessor:** [`SavedArticlesStore`](file:///d:/assignments/CycleTracket/lib/services/saved_articles_store.dart) manages reactive listenables and operations (`saveArticle`, `removeArticle`, `isSaved`, `getSavedArticles`).

#### 2. `settings` Box (Shared)
- **Key `'lang'` (Owner: Member 1):**
  - Type: `String` (`'en'` or `'si'`)
  - Member 3 reads this key via `LangProvider` to automatically update all educational content and UI labels.
- **Key `'pin'` (Owner: Member 1):**
  - Type: `Map<String, dynamic>` containing `{ 'salt': String, 'hash': String }`
  - Member 3 verifies this via `PinService.verify(pin)`.
- **Key `'pin_lock'` (Owner: Member 3):**
  - Type: `Map<String, dynamic>` containing `{ 'fails': int, 'lockedUntil': String }`
  - Manages 30-second lockout throttling after 5 consecutive incorrect PIN attempts. Survives app restart.
- **Key `'profile'` (Owner: Member 1):**
  - Type: `Map<String, dynamic>` containing optional `{ 'displayName': String }`
  - Member 3 reads `displayName` to render `"Ayubowan, {displayName}"` on `EducationHubScreen`. If absent, defaults to `"Ayubowan"`.
- **Key `'quiz'` (Owner: Member 3):**
  - Type: `Map<String, dynamic>` containing `{ 'bestScore': int, 'lastPlayed': String }`
  - Persists personal best score for the Myth Buster quiz.

---

## 4. Service Interfaces & Contracts

### A. `PinService` Interface (`lib/services/pin_service.dart`)

```dart
abstract class PinService {
  Future<bool> isSet();
  Future<bool> verify(String pin);
  Future<void> set(String pin);
}
```

- **Current Implementation:** `MockPinService` uses PBKDF2-SHA256 hashing with `Random.secure()` salt. Supports `--dart-define=DEMO_PIN=1234` for testing.
- **Member 1 Handoff:** Member 1 replaces `MockPinService` with the production biometric/secure PIN service or implements `set(String pin)` during the onboarding flow.

### B. `SessionState` Contract (`lib/services/session_state.dart`)

Global in-memory session manager provided via `Provider<SessionState>`:

```dart
final session = Provider.of<SessionState>(context, listen: false);

// Check if unlocked
if (!session.isUnlocked) { /* Redirect to PrivacyLockScreen */ }

// Immediate panic lock
session.lock();

// Attempt unlock
final success = await session.tryUnlock(enteredPin);
```

### C. `ContentRepository` Contract (`lib/content/content_repository.dart`)

```dart
abstract class ContentRepository {
  Future<List<Article>> getArticlesByCategory(String categoryId);
  Future<Article?> getArticleById(String id);
  Future<List<Article>> searchArticles(String query, Lang lang);
  Future<DailyTip> getDailyTip(DateTime date);
  Future<List<MythQuestion>> getMythQuestions();
}
```

- **Default Implementation:** `BundledRepository` provides 100% offline access to all curated articles, daily tips, and quiz questions.

---

## 5. Stable Article IDs for Cross-Subsystem Deep Linking

Members 2 and 4 can deep-link directly to any educational guide using `AppRoutes.push(context, ArticleScreen(articleId: id))`. The IDs are stable and guaranteed not to change:

| Article ID | Category | Primary Topics | Recommended Integration Point |
| :--- | :--- | :--- | :--- |
| **`'iron-rich-foods'`** | `food-diet` | Iron sources (Mukunuwenna, Gotukola, Dhal), fatigue relief, lime/vitamin C absorption tip | **Member 2:** Link from Daily Insight or Symptom Logging when "Fatigue" is recorded |
| **`'water-hydration'`** | `food-diet` | Hydration benefits, bloating reduction, warm herbal water | **Member 2:** Link when "Cramps" or "Bloating" is logged in Calendar |
| **`'foods-to-limit'`** | `food-diet` | Managing high-salt snacks, caffeine, and processed sugars | **Member 2:** Link from Cycle Insights during luteal phase |
| **`'understanding-your-cycle'`**| `our-body` | 4 cycle phases, hormone transitions, tracking patterns | **Member 2:** Link directly from `DashboardScreen` cycle countdown |
| **`'what-is-a-period'`** | `our-body` | Biological explanation of uterine lining, puberty normalisation | **Member 1:** Link from First-Time Onboarding education |
| **`'hygiene-basics'`** | `our-body` | Pad change intervals (4-6 hrs), clean water washing, infection signs | **Member 4:** Link from Pharmacy hygiene product section |
| **`'hygiene-at-school'`** | `our-body` | Carrying spare pads discreetly, emergency school procedures | **Member 1 & 4:** School wellness resources |

### Example Deep Link Snippet for Member 2

In `DailyLoggingScreen` or `DashboardScreen`:

```dart
import 'package:cycle_care/routes.dart';
import 'package:cycle_care/screens/article_screen.dart';

// When user logs "Cramps" or views cramp relief insight:
InkWell(
  onTap: () {
    AppRoutes.push(
      context,
      const ArticleScreen(articleId: 'water-hydration'),
    );
  },
  child: const Text('Read Cramp Relief Guide →'),
);
```

---

## 6. How Each Member Plugs In

### Member 1: Privacy & Onboarding
1. **Onboarding Completion:** Once language selection and cycle baseline setup are complete, navigate the user to `PinSetupStubScreen` (or your completed PIN setup screen).
2. **Setting PIN:** Call `pinService.set(enteredPin)` to save the PBKDF2 hash to the `settings` box.
3. **Language Switcher:** Update key `'lang'` in the `settings` box with `'en'` or `'si'`. Member 3's `LangBuilder` widgets will immediately rebuild and display the selected language across all educational screens.
4. **Display Name:** If a user enters a display name during profile setup, persist it to `settings.put('profile', {'displayName': name})`. The Education Hub greeting will display it automatically.

### Member 2: Core Tracking & Calendar
1. **Bottom Navigation (`MainScreen`):**
   - Member 3 has registered the `Learn` tab as index `2` in `MainScreen`'s `BottomNavigationBar`.
   - The tab bar items are: `0: Dashboard`, `1: Calendar`, `2: Learn`.
2. **Panic HIDE Support:**
   - Use `AppRoutes.resetTo(context, const MainScreen())` whenever an instant escape back to the dashboard is required.
   - Use the shared `HideButton` widget (`lib/widgets/hide_button.dart`) for consistent styling and accessibility.
3. **Symptom-to-Article Deep Links:**
   - Link symptom logging options to stable article IDs (e.g., `'iron-rich-foods'`, `'water-hydration'`).

### Member 4: Healthcare Access & Pharmacy Directory
1. **Pharmacy Directory Entry Point:**
   - Replace `PharmacyStubScreen` with your full directory implementation.
   - When an article recommends consulting a healthcare professional (e.g., severe cramps, anemia symptoms in `'iron-rich-foods'`), deep-link to the pharmacy search screen:
     ```dart
     AppRoutes.push(context, const PharmacySearchScreen());
     ```

---

## 7. Testing & Verification

### Running the Subsystem Test Suite
```bash
# Run all Member 3 unit, widget, and flow tests
flutter test

# Run static analysis
flutter analyze
```

### Running with Test Mode & Local Metrics Instrumentation
```bash
flutter run --dart-define=TEST_MODE=true --dart-define=DEMO_PIN=1234
```
- A floating badge `TEST • {n} taps` appears on screen.
- Tap the badge to inspect live time-on-task, tap count, HIDE latency, and export the test session JSON to the clipboard.
- See [`docs/user-testing.md`](file:///d:/assignments/CycleTracket/docs/user-testing.md) for full Think-Aloud user testing instructions and the observation sheet.
