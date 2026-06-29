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
| Blocked app gate simulation | ✅ |
| StoreKit 2 paywall ($6.99/mo · $49/yr) | ✅ |
| Streak widget | ✅ |
| Daily reminder notifications | ✅ |
| Weekly activity chart | ✅ |
| Camera permission handling | ✅ |
| App icon | ✅ |

## Open in Xcode

1. Clone: `git clone https://github.com/THFC-COYS/RepScroll.git`
2. Open `RepScroll.xcodeproj`
3. Set **Development Team** on `RepScroll` + `RepScrollWidget` targets
4. Add App Group `group.com.repscroll.shared` to both targets
5. Run on a **physical iPhone** (camera/Vision needs real device)

StoreKit testing: scheme uses `Products.storekit`.

## Architecture

```
RepScroll/
├── App/           Entry, routing, global state
├── Models/        ExerciseType, BlockedApp, DTOs
├── ViewModels/    ChallengeViewModel, HomeViewModel
├── Views/         Onboarding, Home, Challenge, Gate, History, Paywall, Settings
├── Services/      Camera, Vision pose engine, unlocks, StoreKit, notifications
├── CoreData/      WorkoutSessionEntity persistence
└── Utilities/     Theme, widget data bridge
```

## Pose detection

`PoseDetectionService` runs `VNDetectHumanBodyPoseRequest` entirely on-device:

- **Push-ups** — elbow angle down/up transitions with rep cooldown
- **Squats** — hip/knee/ankle angle tracking
- **Plank** — shoulder/hip/ankle alignment; timer runs while form holds

## Blocked apps (v1.1 roadmap)

MVP simulates the gate from Home. Production adds `FamilyControls` + `ManagedSettings` + `DeviceActivityMonitor` extension.

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