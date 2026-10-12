# User Testing Protocol: Private Education Subsystem (Member 3)

This document provides the study design, test script, observation sheet, and metrics instrumentation instructions for evaluating the Private Education Subsystem of **Cycle Care**.

---

## 1. Study Overview

- **Method:** Moderated Think-Aloud Protocol
- **Target Participants:** 5 participants (young women / students representative of target demographic)
- **Environment:** Android device or emulator with airplane mode enabled (offline-first validation)
- **Primary Research Question:** Can users privately, easily, and swiftly navigate to vital health knowledge, save it offline, and exit instantly under privacy urgency?

---

## 2. Success Criteria & Quantitative Targets

| Metric | Target | Description |
| :--- | :--- | :--- |
| **Tap Count** | $\le 4$ taps | From unlock to completing offline save |
| **HIDE Latency** | $< 2.0$ seconds (aim for $< 100$ ms) | Time between pressing HIDE and clearing navigation stack to MainScreen |
| **Task Success Rate** | $100\%$ | Participant successfully completes the full flow |
| **Error Rate** | $\le 1$ mistake / user | PIN keypad misclicks or incorrect category selections |
| **Time-on-Task** | $< 30$ seconds | Total duration from unlock to HIDE |

---

## 3. Test Setup & Instrumentation

### Enabling Test Mode
Launch the app with the test mode flag:
```bash
flutter run --dart-define=TEST_MODE=true --dart-define=DEMO_PIN=1234
```

When `TEST_MODE=true` is enabled:
1. An unobtrusive floating badge appears: **`TEST • {n} taps`**.
2. Tap the badge at any point to open the **User Testing Metrics Dashboard**.
3. Use **"Reset Session"** before starting each participant's run.
4. Use **"Export JSON"** after HIDE is pressed to copy the exact timestamped event log to the clipboard.

### Data Privacy Guarantee
All metrics and timestamps are recorded in-memory on the device only. No participant names, audio, or identifiable information are stored.

---

## 4. Facilitator Script

### Introduction (2 minutes)
> *"Ayubowan, and thank you for taking part in testing Cycle Care today. We are testing the design and usability of the application, not you. There are no right or wrong actions. Please speak your thoughts out loud as you use the app — tell us what you are looking for, what you expect to happen, and if anything feels confusing."*

### Briefing & Scenario (1 minute)
> *"Imagine you want to look up what foods help with low energy during your period. You also want to save this guide so you can re-read it later in your village without data or WiFi signal.*
>
> *Here is your 4-digit PIN: **1234**.*
>
> *When you are done saving the guide, imagine someone suddenly enters the room and you need to immediately hide what you are reading."*

### Task Instructions
1. **Unlock the application** using PIN `1234`.
2. Navigate to the **Learn** tab (Education Hub).
3. Find the **Food & Diet** topic.
4. Open the guide titled **"Iron-Rich Foods For Stronger Energy"**.
5. Save the guide to your **Offline Library**.
6. Press the **HIDE** button to immediately exit to the home screen.

---

## 5. Participant Observation Sheet

| Participant ID | Unlocked (PIN Errors) | Path Taken | Save Successful? | Taps After Unlock ($\le 4$) | HIDE Latency ($< 2$s) | Task Time | Observations & Quotes |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **P01** | `[ ]` Pass (`0`) | Hub $\rightarrow$ Food $\rightarrow$ Article $\rightarrow$ Save | `[ ]` Yes | `___` taps | `___` ms | `___` s | |
| **P02** | `[ ]` Pass (`0`) | Hub $\rightarrow$ Food $\rightarrow$ Article $\rightarrow$ Save | `[ ]` Yes | `___` taps | `___` ms | `___` s | |
| **P03** | `[ ]` Pass (`0`) | Hub $\rightarrow$ Food $\rightarrow$ Article $\rightarrow$ Save | `[ ]` Yes | `___` taps | `___` ms | `___` s | |
| **P04** | `[ ]` Pass (`0`) | Hub $\rightarrow$ Food $\rightarrow$ Article $\rightarrow$ Save | `[ ]` Yes | `___` taps | `___` ms | `___` s | |
| **P05** | `[ ]` Pass (`0`) | Hub $\rightarrow$ Food $\rightarrow$ Article $\rightarrow$ Save | `[ ]` Yes | `___` taps | `___` ms | `___` s | |

---

## 6. Sample Export JSON Structure

```json
{
  "sessionStart": "2026-10-07T01:45:00.000Z",
  "metrics": {
    "taskSuccess": true,
    "timeOnTaskMs": 8450,
    "hideLatencyMs": 18,
    "tapCount": 3,
    "pinErrorCount": 0,
    "totalEvents": 9
  },
  "events": [
    { "name": "lock_shown", "timestamp": "2026-10-07T01:45:00.100Z" },
    { "name": "pin_key", "timestamp": "2026-10-07T01:45:01.200Z", "data": { "key": "1" } },
    { "name": "pin_key", "timestamp": "2026-10-07T01:45:01.400Z", "data": { "key": "2" } },
    { "name": "pin_key", "timestamp": "2026-10-07T01:45:01.600Z", "data": { "key": "3" } },
    { "name": "pin_key", "timestamp": "2026-10-07T01:45:01.800Z", "data": { "key": "4" } },
    { "name": "unlocked", "timestamp": "2026-10-07T01:45:01.850Z" },
    { "name": "nav", "timestamp": "2026-10-07T01:45:03.100Z", "data": { "screen": "CategoryScreen" } },
    { "name": "article_open", "timestamp": "2026-10-07T01:45:05.400Z", "data": { "articleId": "iron-rich-foods" } },
    { "name": "save_offline", "timestamp": "2026-10-07T01:45:07.800Z", "data": { "articleId": "iron-rich-foods" } },
    { "name": "toast_shown", "timestamp": "2026-10-07T01:45:07.820Z", "data": { "message": "Saved for Offline Reading!" } },
    { "name": "hide_tap", "timestamp": "2026-10-07T01:45:10.280Z" },
    { "name": "hide_done", "timestamp": "2026-10-07T01:45:10.298Z" }
  ]
}
```
