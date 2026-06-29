import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationService: NotificationService
    @StateObject private var blockedApps = BlockedAppsService()
    @State private var page = 0

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

            Spacer()
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