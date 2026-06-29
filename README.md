# PushScroll

**Exercise before you scroll.** PushScroll forces a quick burst of movement — push-ups, squats, or plank — before opening blocked social apps.

Built with **SwiftUI**, **Swift 6**, **iOS 18+**, **Vision** pose detection, **Core Data**, and **StoreKit 2**.

## Features

- **Onboarding** — value prop, camera explanation, streaks, optional daily reminders
- **Home dashboard** — animated streak ring, today's reps, quick challenge launch
- **Challenge camera** — real-time Vision push-up rep counting with live feedback
- **Blocked gate (simulation)** — preview the intercept UX before Screen Time integration
- **History & stats** — sessions, streaks, totals via Core Data
- **Paywall** — $6.99/mo · $49/yr subscriptions (StoreKit 2)
- **Widget** — home screen streak display
- **Notifications** — daily workout reminders

## Requirements

- Xcode 16+
- iOS 18+ device or simulator (camera features need a physical device)
- Apple Developer account for subscriptions & App Groups

## Open & Run

1. Clone the repo
2. Open `PushScroll.xcodeproj` in Xcode
3. Set your **Development Team** on both targets (PushScroll + PushScrollWidget)
4. Enable App Group `group.com.pushscroll.shared` in Signing & Capabilities
5. Select a physical iPhone → **Run** (⌘R)

StoreKit testing uses `Products.storekit` — configured in the scheme's Run action.

## Architecture

```
PushScroll/
├── App/              # Entry, global state, routing
├── Models/           # ExerciseType, BlockedApp, DTOs
├── ViewModels/       # MVVM layer
├── Views/            # SwiftUI screens + components
├── Services/         # Camera, Vision, StoreKit, notifications, blocking
├── CoreData/         # Persistence + WorkoutSessionEntity
└── Utilities/        # Theme, widget data bridge
```

## Pose detection (push-ups)

`PoseDetectionService` uses `VNDetectHumanBodyPoseRequest` to track shoulder/elbow/wrist joints. Reps count on down→up transitions when elbow angle crosses configurable thresholds. All processing stays on-device.

## Blocked apps (roadmap)

Current build **simulates** the gate from Home → tap a blocked app. Production path:

1. `FamilyControls` entitlement
2. `ManagedSettings` shield configuration
3. `DeviceActivityMonitor` extension
4. Deep link into challenge flow via App Groups

See `BlockedAppsService.swift` for expansion notes.

## Subscriptions

| Product ID | Price |
|---|---|
| `com.pushscroll.premium.monthly` | $6.99/mo |
| `com.pushscroll.premium.yearly` | $49/yr |

Create matching products in App Store Connect before release.

## Privacy

- Camera frames processed on-device only
- No pose data uploaded
- Apple Privacy Manifest included (`PrivacyInfo.xcprivacy`)

## License

Proprietary — all rights reserved.