# Cycle Care: Member 3 UI & Manual Testing Guide

**Subsystem:** Private Education Subsystem (Member 3)
**Author:** A M S P Aththanayake (IT23184244)
**Target:** Manual QA, User Testing & Feature Evaluation

This guide walks you through testing every feature, screen, and interaction built for Member 3 directly on the running app UI (Desktop, Web, or Android).

---

## Quick Start: How to Run

### Option 1: Standard UI Testing (Direct to Main Screen)

```bash
flutter run
```

*Directly opens the Main Screen with the Dashboard, Calendar, and Learn tabs.*

### Option 2: With Test Mode Overlay (Metrics & Live Tap Counter)

```bash
flutter run --dart-define=TEST_MODE=true
```

*Enables a floating test badge that counts taps, measures HIDE latency, and allows exporting test JSON to clipboard.*

### Option 3: Full Privacy Lock Flow (Test Cold Start PIN Pad)

To test the 4-digit PIN lock screen on launch:

```bash
flutter run --dart-define=DEMO_PIN=1234
```

*(PIN is set to `1234`)*

---

## Test Checklist Summary

|      #      | Feature / Screen                    | Key Actions to Test                                   | Expected Result                                                                  |
| :----------: | :---------------------------------- | :---------------------------------------------------- | :------------------------------------------------------------------------------- |
| **1** | **Learn Tab (Education Hub)** | Tap 3rd tab in bottom navigation                      | Hub opens with Ayubowan greeting, search, Daily Tip, 2x2 grid                    |
| **2** | **Offline Search**            | Type`"iron"`, `"cramps"`, or `"water"`          | Instant filtered article results appear below search box                         |
| **3** | **Daily Health Tip**          | Tap "Read More" on dark maroon tip card               | Directly opens the associated full article                                       |
| **4** | **Category Screen**           | Tap**"Food & Diet"** topic tile                 | Shows filter chips (`All Tips`, `Cramp Relief`, `Vitamins`) & article list |
| **5** | **Filter Chips**              | Tap`Cramp Relief` or `Vitamins`                   | List reactively filters down to matching guides                                  |
| **6** | **Article Reader**            | Tap**"Iron-Rich Foods For Stronger Energy"**    | Opens pink hero, category badge, village tip callout, save button                |
| **7** | **Offline Save Toggle**       | Tap**"Save To Offline Library"** pill button    | Turns into green**"✓ Saved Offline"**; dark toast notification appears    |
| **8** | **Reversible Unsave**         | Tap**"✓ Saved Offline"** again                 | Reverts to "Save To Offline Library"; toast confirms removal                     |
| **9** | **Panic HIDE Button**         | Tap top-right**"HIDE ✕"** pill                 | Instant exit back to MainScreen with zero delay; Back cannot re-enter            |
| **10** | **Offline Library**           | Tap**"Saved Library"** tile on Hub              | Shows "Zero Internet Required" banner, saved list with date & read time          |
| **11** | **Read Offline**              | Tap**"Read Offline"** pill on any saved card    | Immediately opens the article in full reading view                               |
| **12** | **Library Remove**            | Tap trash/remove button on a saved card               | Item animates away; empty state shows if all removed                             |
| **13** | **Myth Buster Quiz**          | Tap**"Myth Buster"** maroon tile on Hub         | Starts 5-question quiz with progress bar & question card                         |
| **14** | **Quiz Feedback**             | Tap**"It's a MYTH"** or **"It's a FACT"** | Shows instant green/red badge with medical explanation & Next button             |
| **15** | **Quiz Results**              | Finish Question 5                                     | Displays final score, persists personal best score, offers Play Again            |
| **16** | **Test Mode Overlay**         | Tap floating**`TEST • {n} taps`** badge      | Opens live metrics dialog with tap count, time on task, & JSON export            |

---

## Step-by-Step UI Walkthrough

### Step 1: Access the Education Hub (`EducationHubScreen`)

1. Look at the bottom navigation bar with 3 tabs:
   - **Dashboard** (tab 1 - Member 2)
   - **Calendar** (tab 2 - Member 2)
   - **Learn** (tab 3 - Member 3, book icon 📖)
2. Tap the **Learn** tab.
3. **Verify:**
   - Header shows a flower icon and *"Ayubowan"* greeting.
   - Search input box with placeholder: *"Search health guides, cramps…"*.
   - Dark maroon **Daily Health Tip** card with a tea cup icon and *"Read More"* pill.
   - **Explore Topics** 2x2 grid:
     - 🌸 **Our Body** (*"Hormones & Cycle"*)
     - 🥗 **Food & Diet** (*"Iron-Rich Meals"*)
     - ❓ **Myth Buster** (*"Fun Quiz Game"* - highlighted maroon tile)
     - 📥 **Saved Library** (*"{n} Guides Offline"* - shows live count)

---

### Step 2: Test Offline Search

1. In the search box, type: `cramp`
   - **Verify:** Instant results show articles like *"Water & Hydration"* and *"Foods To Avoid"*.
2. Clear the box or type: `iron`
   - **Verify:** Shows *"Iron-Rich Foods For Stronger Energy"*.
3. Tap on any search result row.
   - **Verify:** Opens the full `ArticleScreen`. Press the back chevron to return to the Hub.

---

### Step 3: Test Category List & Filter Chips (`CategoryScreen`)

1. From the Hub, tap the **Food & Diet** tile.
2. **Verify:**
   - Top bar displays `"Food & Diet"` with a back button.
   - Filter chips row: `All Tips`, `Cramp Relief`, `Vitamins`.
3. Tap **`Vitamins`**:
   - **Verify:** Filter chip highlights with primary pink styling, and the list filters to show `"Iron-Rich Foods"`.
4. Tap **`All Tips`**:
   - **Verify:** All 3 nutrition articles reappear.

---

### Step 4: Test Article Reading & Save to Offline (`ArticleScreen`)

1. Tap the first article: **"Iron-Rich Foods For Stronger Energy"**.
2. **Verify Screen Elements:**
   - Soft pink hero illustration banner at the top.
   - Top-left circular back button.
   - Top-right high-contrast **`HIDE ✕`** button.
   - White overlapping sheet with rounded corners.
   - Category pill: `"Nutrition Guide"`.
   - Two-toned title (*"Iron-Rich Foods"* in dark maroon, *"For Stronger Energy"* in accent pink).
   - Reading time: `"4 min read"`.
   - Structured sections with bullet lists of local Sri Lankan foods (*Mukunuwenna, Kankun, Dhal, Eggs, Fish*).
   - **"Village Tip"** callout card with leaf icon (*Squeezing lime increases iron absorption*).
3. **Save Offline Interaction:**
   - Tap the bottom pill button **"Save To Offline Library"**.
   - **Verify:**
     1. Button changes to green outlined chip: **`✓ Saved Offline`**.
     2. A dark pill toast appears at the bottom: *"Saved for Offline Reading!"* with subtext *"You can read this anytime without Data"*.
4. **Reversible Unsave Interaction:**
   - Tap **`✓ Saved Offline`** again.
   - **Verify:** Button reverts to *"Save To Offline Library"* and toast announces removal.
   - Tap once more to leave it saved for the next step!

---

### Step 5: Test the Panic HIDE Button (REQ-3.1 Privacy Guarantee)

1. While reading the article, tap the top-right **`HIDE ✕`** button.
2. **Verify:**
   - The screen immediately swaps to `MainScreen` with **zero latency (<100ms)** and no sliding transition.
   - Any active toast is dismissed instantly.
3. **Verify the Back Button Test:**
   - Press the Android Back button or Browser Back button.
   - **Expected:** The browser/app **CANNOT** return to the private article! The stack has been completely cleared.

---

### Step 6: Test Offline Library (`OfflineLibraryScreen`)

1. On the **Learn** tab, notice the **Saved Library** tile now says **`1 Guides Offline`** (or more).
2. Tap the **Saved Library** tile.
3. **Verify:**
   - Top bar reads `"Offline Library"`.
   - Green banner: **"Zero Internet Required"** (*"Read without data or village signal issues"*).
   - Your saved article card is listed with:
     - Article icon & title.
     - Subtext: *"Saved on {Date} · 4 min read"*.
     - Green **"Read Offline"** pill button.
     - Trash/remove icon.
4. Tap **"Read Offline"**:
   - **Verify:** Immediately opens the article for reading.
5. Go back and tap the trash/remove icon:
   - **Verify:** Article is removed from the list.
   - If no articles remain, a friendly empty-state illustration appears (*"Nothing saved yet"*) with a **"Browse topics"** button that navigates back to the Hub.

---

### Step 7: Test Myth Buster Quiz (`MythBusterScreen`)

1. On the **Learn** tab, tap the maroon **Myth Buster** tile (*"Fun Quiz Game"*).
2. **Verify:**
   - Dark maroon immersive theme with white question card.
   - Progress bar at top with **"QUESTION 1 OF 5"**.
   - Question statement in quotes (e.g., *"You should never wash your hair during periods."*).
   - Two stacked response buttons:
     - Pink filled: **"It's a MYTH"**
     - Outlined: **"It's a FACT"**
3. Tap **"It's a MYTH"**:
   - **Verify:** Feedback banner appears with a green checkmark, positive encouragement, and medical explanation.
4. Tap **"Next Question"**:
   - **Verify:** Advances to Question 2 of 5, progress bar moves forward.
5. Finish all 5 questions:
   - **Verify Results Screen:**
     - Shows final score (e.g. *"You got 5 of 5"*).
     - Persists your **"Personal Best"** score in local Hive storage.
     - Two action buttons: **"Play Again"** (restarts with shuffled questions) and **"Back to Hub"**.

---

### Step 8: Test Mode Overlay & Metrics Export (When running with `TEST_MODE=true`)

1. If running with `--dart-define=TEST_MODE=true`, locate the small dark floating badge: **`TEST • {n} taps`**.
2. **Dragging:** Click and drag the badge to any corner of the screen.
3. **Tap Counter:** Notice the tap count increments with your navigation and save actions.
4. **Metrics Dashboard:**
   - Tap the badge.
   - A modal bottom sheet slides up showing:
     - **Taps (Post-Unlock):** Target $\le 4$ taps.
     - **Time on Task:** Duration from unlock to HIDE.
     - **HIDE Latency:** Measured in milliseconds ($<2000$ms target, typically $<20$ms).
     - **Task Success Badge:** Green *"Task Completed Successfully"* once full flow is done.
5. **Session Actions:**
   - Tap **"Export JSON"**: Copies the entire timestamped session log to your clipboard.
   - Tap **"Reset Session"**: Clears event log and resets taps to 0 for a new test run.

---

## 4-Tap Core Task Flow Acceptance Test

To verify the core Milestone requirement (**4 taps or fewer from Hub to Save**):

1. **Tap 1:** Tap **Food & Diet** topic tile on the Hub.
2. **Tap 2:** Tap **Iron-Rich Foods** article row on Category screen.
3. **Tap 3:** Tap **Save To Offline Library** button on Article screen.
4. **Tap 4:** Tap **HIDE ✕** button to exit.

- **Result:** Task completed in **exactly 3 taps to save (4 taps total including HIDE)** $\le 4$ target!
