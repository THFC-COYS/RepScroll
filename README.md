# RepScroll

**Reps before scroll.** An iOS app that gates social media behind quick exercise — push-ups, squats, or plank — with on-device Vision rep counting.

SwiftUI · Swift 6 · iOS 18+ · Core Data · StoreKit 2 · WidgetKit

## MVP feature set

| Feature | Status |
|---------|--------|
| Onboarding + blocked app picker | ✅ |
| Vision push-up rep counting | ✅ |
| Vision squat rep counting | ✅ |
| Vision plank hold timer | ✅ |
| Streak + session history (Core Data) | ✅ |
| 15-min scroll unlock windows | ✅ |
| Real Screen Time blocking (FamilyControls) with simulation fallback | ✅ v1.1 |
| StoreKit 2 paywall ($6.99/mo · $49/yr) | ✅ |
| Streak widget | ✅ |
| Daily reminder notifications | ✅ |
| Weekly activity chart | ✅ |
| Camera permission handling | ✅ |
| App icon | ✅ |

## Open in Xcode

1. Clone: `git clone https://github.com/THFC-COYS/RepScroll.git`
2. Open `RepScroll.xcodeproj`
3. Set **Development Team** on all four targets: `RepScroll`, `RepScrollWidget`, `RepScrollMonitor`, `RepScrollShield`
4. Add App Group `group.com.repscroll.shared` to all targets; confirm the **Family Controls** capability on `RepScroll`, `RepScrollMonitor`, and `RepScrollShield`
5. Run on a **physical iPhone** (camera/Vision needs a real device, and Screen Time behavior cannot be validated in the simulator)

StoreKit testing: scheme uses `Products.storekit`.

## Architecture

```
RepScroll/
├── App/           Entry, routing, global state
├── Models/        ExerciseType, BlockedApp, DTOs
├── ViewModels/    ChallengeViewModel, HomeViewModel
├── Views/         Onboarding, Home, Challenge, Gate, History, Paywall, Settings
├── Services/      Camera, Vision pose engine, unlocks, StoreKit, notifications, Screen Time
├── CoreData/      WorkoutSessionEntity persistence
├── Shared/        ShieldManager, compiled into the app and the Screen Time extensions
└── Utilities/     Theme, widget data bridge

RepScrollMonitor/  DeviceActivityMonitor extension (re-applies shields)
RepScrollShield/   ShieldConfiguration extension (branded shield)
```

## Pose detection

`PoseDetectionService` runs `VNDetectHumanBodyPoseRequest` entirely on-device:

- **Push-ups** — elbow angle down/up transitions with rep cooldown
- **Squats** — hip/knee/ankle angle tracking
- **Plank** — shoulder/hip/ankle alignment; timer runs while form holds

## Blocked apps (v1.1, implemented)

Real system-level blocking is built, with the v1.0 simulation kept as an automatic fallback:

- **Authorization:** `ScreenTimeService` requests Screen Time authorization via `AuthorizationCenter` (`.individual`) during onboarding and in Settings. The mode is a runtime decision (`AppConfig.screenTimeIntegration`): `.familyControls` when authorization is approved, `.simulation` otherwise, so the gate flow is never a dead end.
- **Picker:** approved users pick the real apps, categories, and web domains to protect with `FamilyActivityPicker`. The `FamilyActivitySelection` is JSON-encoded into the App Group suite (`group.com.repscroll.shared`) so the extensions read the same selection.
- **Shields:** `ShieldManager` (`RepScroll/Shared`, compiled into the app and the extensions) applies `ManagedSettings` shields from the selection. Completing a gate challenge clears the shields and schedules a one-shot `DeviceActivity` window for the unlock; when the window ends, the **RepScrollMonitor** extension (`DeviceActivityMonitor`) re-applies them, and the app reconciles again on launch/foreground.
- **Shield UI:** the **RepScrollShield** extension (`ShieldConfiguration`) shows a branded "Earn your scroll" shield on protected apps.
- **Targets:** `RepScrollMonitor` (`com.repscroll.app.monitor`) and `RepScrollShield` (`com.repscroll.app.shield`) sit alongside the widget extension; all three plus the app carry the App Group, and the app and Screen Time extensions carry `com.apple.developer.family-controls`.

Distribution still needs Apple's Family Controls (Distribution) entitlement approval for the app and each extension bundle ID; development builds run with the development entitlement.

## Subscriptions

| Product ID | Price |
|---|---|
| `com.repscroll.premium.monthly` | $6.99/mo |
| `com.repscroll.premium.yearly` | $49/yr |

Premium: 30-minute unlock windows + unlimited daily gates.

## Regenerate app icon

```bash
python3 scripts/generate_app_icon.py
```

## Privacy

Camera frames never leave the device. Apple Privacy Manifest included.