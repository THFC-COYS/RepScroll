import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var appState: AppState
    @StateObject private var blockedApps = BlockedAppsService()
    @AppStorage("unlockMinutes") private var unlockMinutes = 15

    var body: some View {
        NavigationStack {
            List {
                Section("Subscription") {
                    if subscriptionService.isPremium {
                        Label("Premium active", systemImage: "crown.fill")
                            .foregroundStyle(RepScrollTheme.accentSecondary)
                    } else {
                        Button("Upgrade to Premium") {
                            appState.showPaywall = true
                        }
                    }
                    Button("Restore purchases") {
                        Task { await subscriptionService.restorePurchases() }
                    }
                }

                Section("Pose detection") {
                    Picker("Sensitivity", selection: Binding(
                        get: { appState.poseSensitivity },
                        set: { appState.poseSensitivity = $0 }
                    )) {
                        ForEach(PoseSensitivity.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }

                Section("Unlock window") {
                    Stepper("Minutes per unlock: \(unlockMinutes)", value: $unlockMinutes, in: 5...60, step: 5)
                }

                Section("Daily goal") {
                    Picker("Exercise", selection: Binding(
                        get: { appState.preferredExercise },
                        set: { appState.preferredExercise = $0 }
                    )) {
                        ForEach(ExerciseType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    Stepper("Goal: \(appState.dailyRepGoal)", value: $appState.dailyRepGoal, in: 5...50, step: 5)
                }

                Section("Reminders") {
                    Toggle("Daily reminder", isOn: $appState.remindersEnabled)
                        .onChange(of: appState.remindersEnabled) { _, enabled in
                            Task {
                                await notificationService.scheduleDailyReminder(
                                    hour: appState.reminderHour,
                                    minute: appState.reminderMinute,
                                    enabled: enabled
                                )
                            }
                        }
                    if appState.remindersEnabled {
                        DatePicker(
                            "Time",
                            selection: reminderDateBinding,
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                Section("Blocked apps") {
                    ForEach(blockedApps.allApps) { app in
                        Toggle(app.name, isOn: Binding(
                            get: { blockedApps.enabledApps.contains(app.id) },
                            set: { _ in blockedApps.toggle(app) }
                        ))
                    }
                    Text("Screen Time API integration expands this to real system-level blocking.")
                        .font(.caption)
                        .foregroundStyle(RepScrollTheme.textSecondary)
                }

                Section("Privacy") {
                    Label("Camera stays on-device", systemImage: "eye.slash.fill")
                    Label("Pose data never uploaded", systemImage: "icloud.slash.fill")
                    Link("Privacy Policy", destination: URL(string: AppConfig.privacyPolicyURL)!)
                    Link("Terms of Use", destination: URL(string: AppConfig.termsURL)!)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    }
                    Button("Replay onboarding") {
                        appState.hasCompletedOnboarding = false
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(RepScrollTheme.background)
            .navigationTitle("Settings")
        }
    }

    private var reminderDateBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = appState.reminderHour
                components.minute = appState.reminderMinute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                appState.reminderHour = parts.hour ?? 8
                appState.reminderMinute = parts.minute ?? 0
                Task {
                    await notificationService.scheduleDailyReminder(
                        hour: appState.reminderHour,
                        minute: appState.reminderMinute,
                        enabled: appState.remindersEnabled
                    )
                }
            }
        )
    }
}