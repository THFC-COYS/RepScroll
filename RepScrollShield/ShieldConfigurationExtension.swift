import ManagedSettings
import ManagedSettingsUI
import UIKit

/// ShieldConfiguration extension (target: RepScrollShield).
///
/// Provides the branded shield the system shows when the user opens a
/// protected app, category, or web domain during a block. Colors mirror
/// RepScrollTheme in the app target (extensions cannot import it):
/// background #0A0A0F, accent #FF6B35.
///
/// Button note: without a separate ShieldAction extension there is no
/// code behind the button, so the primary button simply dismisses the
/// shield. iOS offers no public API for a shield button to open another
/// app, so the copy tells the user to open RepScroll and earn the unlock.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        brandedShield()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        brandedShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        brandedShield()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        brandedShield()
    }

    private func brandedShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemDark,
            backgroundColor: UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1),
            icon: UIImage(systemName: "figure.strengthtraining.traditional"),
            title: ShieldConfiguration.Label(
                text: "Earn your scroll",
                color: UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1)
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is protected by RepScroll. Open RepScroll and do your reps to unlock it.",
                color: UIColor(red: 0.60, green: 0.60, blue: 0.65, alpha: 1)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Close",
                color: UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)
            ),
            primaryButtonBackgroundColor: UIColor(red: 1.00, green: 0.42, blue: 0.21, alpha: 1)
        )
    }
}
