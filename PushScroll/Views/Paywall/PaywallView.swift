import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var subscriptionService: SubscriptionService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly

    enum Plan { case monthly, yearly }

    var body: some View {
        ZStack {
            PushScrollTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    features
                    planPicker
                    purchaseButton
                    restoreButton
                    legal
                }
                .padding()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(PushScrollTheme.heroGradient)
            Text("PushScroll Premium")
                .font(.largeTitle.weight(.bold))
            Text("Unlimited app gates, all exercises, streak widgets, and zero ads.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(PushScrollTheme.textSecondary)
        }
        .foregroundStyle(PushScrollTheme.textPrimary)
        .padding(.top, 20)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow("lock.shield.fill", "Unlimited blocked-app challenges")
            featureRow("camera.fill", "Squat & plank AI counting (coming)")
            featureRow("rectangle.grid.2x2.fill", "Home screen streak widget")
            featureRow("bell.badge.fill", "Smart reminder scheduling")
        }
        .pushScrollCard()
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(PushScrollTheme.accent)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(PushScrollTheme.textPrimary)
        }
    }

    private var planPicker: some View {
        VStack(spacing: 12) {
            if let yearly = subscriptionService.yearlyProduct {
                planCard(
                    plan: .yearly,
                    title: "Yearly",
                    price: yearly.displayPrice,
                    subtitle: "Best value · ~$4.08/mo",
                    badge: "SAVE 40%"
                )
            } else {
                placeholderPlan(title: "Yearly", price: "$49.00/yr", subtitle: "Best value")
            }

            if let monthly = subscriptionService.monthlyProduct {
                planCard(
                    plan: .monthly,
                    title: "Monthly",
                    price: monthly.displayPrice,
                    subtitle: "Cancel anytime",
                    badge: nil
                )
            } else {
                placeholderPlan(title: "Monthly", price: "$6.99/mo", subtitle: "Cancel anytime")
            }
        }
    }

    private func planCard(plan: Plan, title: String, price: String, subtitle: String, badge: String?) -> some View {
        Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(PushScrollTheme.success.opacity(0.2))
                                .foregroundStyle(PushScrollTheme.success)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PushScrollTheme.textSecondary)
                }
                Spacer()
                Text(price)
                    .font(.headline)
            }
            .foregroundStyle(PushScrollTheme.textPrimary)
            .padding()
            .background(selectedPlan == plan ? PushScrollTheme.accent.opacity(0.15) : PushScrollTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selectedPlan == plan ? PushScrollTheme.accent : Color.white.opacity(0.06), lineWidth: 2)
            )
        }
    }

    private func placeholderPlan(title: String, price: String, subtitle: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(PushScrollTheme.textSecondary)
            }
            Spacer()
            Text(price).font(.headline)
        }
        .foregroundStyle(PushScrollTheme.textPrimary)
        .padding()
        .background(PushScrollTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var purchaseButton: some View {
        Button {
            Task {
                let product: Product?
                switch selectedPlan {
                case .monthly: product = subscriptionService.monthlyProduct
                case .yearly: product = subscriptionService.yearlyProduct
                }
                if let product {
                    try? await subscriptionService.purchase(product)
                    if subscriptionService.isPremium { dismiss() }
                }
            }
        } label: {
            Group {
                if subscriptionService.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Start free trial")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlowButtonStyle())
        .disabled(subscriptionService.isLoading)
    }

    private var restoreButton: some View {
        Button("Restore purchases") {
            Task { await subscriptionService.restorePurchases() }
        }
        .font(.subheadline)
        .foregroundStyle(PushScrollTheme.textSecondary)
    }

    private var legal: some View {
        Text("Payment charged to Apple ID. Subscriptions auto-renew unless cancelled 24h before period end. Manage in Settings → Apple ID → Subscriptions.")
            .font(.caption2)
            .multilineTextAlignment(.center)
            .foregroundStyle(PushScrollTheme.textSecondary.opacity(0.7))
            .padding(.bottom, 20)
    }
}