import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var notificationService: NotificationService
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "hand.raised.fill",
            title: "Scroll less.\nMove more.",
            subtitle: "PushScroll blocks the doomscroll trap. Do a quick burst of exercise before social apps open."
        ),
        OnboardingPage(
            icon: "camera.viewfinder",
            title: "Camera counts\nyour reps",
            subtitle: "Vision AI tracks push-ups in real time. No cheating — your body stays in frame."
        ),
        OnboardingPage(
            icon: "flame.fill",
            title: "Build a streak",
            subtitle: "Log daily sessions, earn your scroll time, and watch your streak grow."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            title: "Daily nudge",
            subtitle: "Optional morning reminder to knock out reps before the feed pulls you in."
        ),
    ]

    var body: some View {
        ZStack {
            PushScrollTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        onboardingPage(item)
                            .tag(index)
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

            ZStack {
                Circle()
                    .fill(PushScrollTheme.heroGradient.opacity(0.25))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)
                Image(systemName: item.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(PushScrollTheme.heroGradient)
            }

            Text(item.title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(PushScrollTheme.textPrimary)

            Text(item.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(PushScrollTheme.textSecondary)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
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
                .buttonStyle(GlowButtonStyle(color: PushScrollTheme.surfaceElevated))
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