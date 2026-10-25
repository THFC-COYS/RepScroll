import SwiftUI
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var screenTimeService: ScreenTimeService
    @StateObject private var blockedApps = BlockedAppsService()
    @AppStorage("unlockMinutes") private var unlockMinutes = 15
    @State private var showAppPicker = false

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

                Section("Screen Time blocking") {
                    if screenTimeService.isApproved {
                        Label("Real blocking is on", systemImage: "lock.shield.fill")
                            .foregroundStyle(RepScrollTheme.success)
                        HStack {
                            Text("Protected selections")
                            Spacer()
                            Text("\(screenTimeService.selectedCount)")
                                .foregroundStyle(RepScrollTheme.textSecondary)
                        }
                        Button("Choose protected apps") { showAppPicker = true }
                        Text("Protected apps stay shielded until you earn an unlock. RepScroll never sees or collects your usage data.")
                            .font(.caption)
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    } else if screenTimeService.isDenied {
                        Label("Screen Time access is off", systemImage: "lock.slash.fill")
                            .foregroundStyle(RepScrollTheme.textSecondary)
                        Button("Request access again") {
                            Task { await screenTimeService.requestAuthorization() }
                        }
                        Text("RepScroll is running in preview mode. If access stays off, manage Screen Time permissions for RepScroll in the Settings app.")
                            .font(.caption)
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    } else {
                        Button("Enable Screen Time blocking") {
                            Task { await screenTimeService.requestAuthorization() }
                        }
                        Text("Shield your worst apps for real. You pick them in the system picker; nothing about your usage is collected.")
                            .font(.caption)
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    }
                }
                .familyActivityPicker(isPresented: $showAppPicker, selection: $screenTimeService.selection)

                if screenTimeService.isSimulationMode {
                    Section("Blocked apps (preview)") {
                        ForEach(blockedApps.allApps) { app in
                            Toggle(app.name, isOn: Binding(
                                get: { blockedApps.enabledApps.contains(app.id) },
                                set: { _ in blockedApps.toggle(app) }
                            ))
                        }
                        Text("Preview list for simulation mode. Turn on Screen Time blocking above to shield apps for real.")
                            .font(.caption)
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    }
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
                        Text(AppConfig.appVersion)
                            .foregroundStyle(RepScrollTheme.textSecondary)
                    }
                    Link("Support & feedback", destination: URL(string: AppConfig.supportURL)!)
                    Link("Email support", destination: URL(string: "mailto:\(AppConfig.supportEmail)")!)
                    Button("Replay onboarding") {
                        appState.hasCompletedOnboarding = false
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(RepScrollTheme.background)
            .navigationTitle("Settings")
            .onAppear { screenTimeService.refreshAuthorizationStatus() }
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