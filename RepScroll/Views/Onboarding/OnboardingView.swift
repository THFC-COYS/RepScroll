import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationService: NotificationService
    @EnvironmentObject private var screenTimeService: ScreenTimeService
    @StateObject private var blockedApps = BlockedAppsService()
    @State private var page = 0
    @State private var showAppPicker = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "hand.raised.fill",
            title: "Scroll less.\nMove more.",
            subtitle: "RepScroll puts a wall between you and the feed. Move your body first — scroll second."
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "AI counts\nyour reps",
            subtitle: "Push-ups, squats, plank — Vision tracks form on-device. Nothing leaves your phone."
        ),
        OnboardingPage(
            icon: "flame.fill",
            title: "Build a streak",
            subtitle: "Daily sessions stack. The ring fills. The streak grows. You win."
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            title: "Pick your\ntemptations",
            subtitle: "Choose which apps need reps before they open. Start with your worst offenders."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            title: "Morning nudge",
            subtitle: "Optional reminder before the algorithm gets you."
        ),
    ]

    var body: some View {
        ZStack {
            RepScrollTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        if index == 3 {
                            blockedAppsPage.tag(index)
                        } else {
                            onboardingPage(item).tag(index)
                        }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                bottomBar
            }
        }
    }

    private func onboardingPage(_ item: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()
            heroIcon(item.icon)
            Text(item.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(RepScrollTheme.textPrimary)
            Text(item.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(RepScrollTheme.textSecondary)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .padding()
    }

    private var blockedAppsPage: some View {
        VStack(spacing: 20) {
            Spacer()
            heroIcon("lock.shield.fill")
            Text("Block these apps")
                .font(.title.weight(.bold))
                .foregroundStyle(RepScrollTheme.textPrimary)

            if screenTimeService.isApproved {
                approvedPickerContent
            } else if screenTimeService.isDenied {
                deniedPickerContent
            } else {
                authorizationPromptContent
            }

            Spacer()
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $screenTimeService.selection)
        .onAppear { screenTimeService.refreshAuthorizationStatus() }
    }

    /// Real blocking is on: the user picks the actual apps, categories, and
    /// sites to shield with the system picker.
    private var approvedPickerContent: some View {
        VStack(spacing: 16) {
            Text(screenTimeService.selectedCount > 0
                 ? "\(screenTimeService.selectedCount) apps, categories, and sites are protected. They stay shielded until you earn an unlock."
                 : "Pick the apps that need reps before they open. They stay shielded until you earn an unlock.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(RepScrollTheme.textSecondary)
                .padding(.horizontal, 32)

            Button("Choose protected apps") { showAppPicker = true }
                .buttonStyle(GlowButtonStyle())
                .padding(.horizontal, 24)
        }
    }

    /// Authorization has not been asked yet: offer the real thing first,
    /// with the preview list as the no-pressure fallback.
    private var authorizationPromptContent: some View {
        VStack(spacing: 16) {
            Text("Let RepScroll shield these apps for real, using Screen Time. You pick the apps, and nothing about your usage is collected.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(RepScrollTheme.textSecondary)
                .padding(.horizontal, 32)

            Button("Enable Screen Time blocking") {
                Task { await screenTimeService.requestAuthorization() }
            }
            .buttonStyle(GlowButtonStyle())
            .padding(.horizontal, 24)

            simulationPickerList(caption: "Or start with the preview list. You can turn on real blocking later in Settings.")
        }
    }

    /// Denied: never a dead end. The simulation gate still runs.
    private var deniedPickerContent: some View {
        VStack(spacing: 16) {
            Text("Screen Time access is off, so RepScroll runs in preview mode for now. Turn it on any time in Settings to block apps for real.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(RepScrollTheme.textSecondary)
                .padding(.horizontal, 32)

            simulationPickerList(caption: nil)
        }
    }

    private func simulationPickerList(caption: String?) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                ForEach(blockedApps.allApps) { app in
                    Toggle(isOn: Binding(
                        get: { blockedApps.enabledApps.contains(app.id) },
                        set: { _ in blockedApps.toggle(app) }
                    )) {
                        Label(app.name, systemImage: app.iconSystemName)
                    }
                    .tint(RepScrollTheme.accent)
                }
            }
            .repScrollCard()
            .padding(.horizontal, 24)

            if let caption {
                Text(caption)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(RepScrollTheme.textSecondary)
                    .padding(.horizontal, 32)
            }
        }
    }

    private func heroIcon(_ name: String) -> some View {
        ZStack {
            Circle()
                .fill(RepScrollTheme.heroGradient.opacity(0.25))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
            Image(systemName: name)
                .font(.system(size: 56))
                .foregroundStyle(RepScrollTheme.heroGradient)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if page == pages.count - 1 {
                Button("Enable reminders") {
                    Task {
                        let granted = await notificationService.requestPermission()
                        appState.remindersEnabled = granted
                        if granted {
                            await notificationService.scheduleDailyReminder(
                                hour: appState.reminderHour,
                                minute: appState.reminderMinute,
                                enabled: true
                            )
                        }
                    }
                }
                .buttonStyle(GlowButtonStyle(color: RepScrollTheme.surfaceElevated))
            }

            Button(page == pages.count - 1 ? "Get started" : "Continue") {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    withAnimation { appState.hasCompletedOnboarding = true }
                }
            }
            .buttonStyle(GlowButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}