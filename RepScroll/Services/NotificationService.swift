import UserNotifications
import os

/// Schedules daily workout reminder notifications.
@MainActor
final class NotificationService: ObservableObject {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.repscroll.app", category: "Notifications")
    private let reminderIdentifier = "com.repscroll.daily.reminder"

    init() {
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refreshStatus()
            return granted
        } catch {
            logger.error("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int, enabled: Bool) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
        guard enabled else { return }

        if authorizationStatus != .authorized {
            let granted = await requestPermission()
            guard granted else { return }
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let content = UNMutableNotificationContent()
        content.title = AppConfig.reminderTitle
        content.body = AppConfig.reminderBody
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            logger.error("Schedule failed: \(error.localizedDescription)")
        }
    }
}