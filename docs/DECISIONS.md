# RepScroll MVP — Locked Decisions (v1.0)

All eight pillars decided. No open questions for launch.

## 1. Platform

| Decision | Value |
|----------|-------|
| Minimum iOS | 18.0 |
| Language | Swift 6, strict concurrency |
| UI | SwiftUI only |
| Devices | iPhone only (no iPad) |
| Appearance | Dark mode only |
| Bundle ID | `com.repscroll.app` |
| App Group | `group.com.repscroll.shared` |

## 2. Vision & camera

| Decision | Value |
|----------|-------|
| Camera | Front-facing only |
| Processing | 100% on-device, never uploaded |
| Exercises | Push-ups, squats, plank (all Vision) |
| Rep debounce | 0.55s between counts |
| Sensitivity | Easy / Normal / Strict (Settings) |
| Gate exercise | Always push-ups, 10 reps |

## 3. Core Data

| Decision | Value |
|----------|-------|
| Sync | None (local only) |
| Entity | `WorkoutSessionEntity` |
| History cap | 200 sessions in UI |

## 4. StoreKit

| Decision | Value |
|----------|-------|
| Monthly | `com.repscroll.premium.monthly` — $6.99, 7-day free trial |
| Yearly | `com.repscroll.premium.yearly` — $49 (default selected on paywall) |
| Premium perks | 30-min unlocks, unlimited daily gates |
| Free tier | 15-min unlocks, 1 gate challenge per day |

## 5. UI / UX

| Decision | Value |
|----------|-------|
| Accent | Orange `#FF6B35` on near-black |
| Tabs | Home → Challenge → History → Settings |
| Completion | Confetti + haptics |
| Paywall | Dismissible, yearly highlighted |

## 6. Core features

| Decision | Value |
|----------|-------|
| Default blocked apps | Instagram, TikTok, X |
| Gate flow | Tap app → reps → timed unlock |
| Screen Time | **Simulation** in v1.0 (v1.1 = FamilyControls) |
| Onboarding | 5 pages incl. app picker |

## 7. Widget

| Decision | Value |
|----------|-------|
| Families | Small + Medium |
| Data | Current streak + today's reps |
| Refresh | Every hour |

## 8. Notifications

| Decision | Value |
|----------|-------|
| Default | Opt-in during onboarding |
| Time | 8:00 AM local |
| Copy | "10 reps before the scroll. Your streak is waiting." |

## Post-MVP (v1.1)

- FamilyControls real blocking
- App Store marketing site
- CloudKit sync (if needed)