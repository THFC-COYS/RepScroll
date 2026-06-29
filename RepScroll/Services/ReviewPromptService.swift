import StoreKit
import UIKit

/// Ask for App Store review after meaningful milestones (max once per version).
enum ReviewPromptService {
    private static let lastPromptKey = "review.lastPromptVersion"

    static func considerPrompt(streak: Int, totalSessions: Int) {
        let milestones = [7, 14, 30]
        guard milestones.contains(streak) || totalSessions == 5 || totalSessions == 20 else { return }

        let version = AppConfig.appVersion
        guard UserDefaults.standard.string(forKey: lastPromptKey) != version else { return }
        UserDefaults.standard.set(version, forKey: lastPromptKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}