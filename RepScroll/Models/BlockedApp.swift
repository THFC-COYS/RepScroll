import Foundation

/// Placeholder model for apps that RepScroll will gate behind exercise challenges.
/// Expand via Screen Time / FamilyControls entitlements in production.
struct BlockedApp: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let iconSystemName: String
    let accentHex: String

    static let placeholders: [BlockedApp] = [
        BlockedApp(id: "instagram", name: "Instagram", bundleIdentifier: "com.burbn.instagram", iconSystemName: "camera.circle.fill", accentHex: "E1306C"),
        BlockedApp(id: "tiktok", name: "TikTok", bundleIdentifier: "com.zhiliaoapp.musically", iconSystemName: "music.note.list", accentHex: "69C9D0"),
        BlockedApp(id: "x", name: "X", bundleIdentifier: "com.atebits.Tweetie2", iconSystemName: "bubble.left.and.bubble.right.fill", accentHex: "1DA1F2"),
        BlockedApp(id: "youtube", name: "YouTube", bundleIdentifier: "com.google.ios.youtube", iconSystemName: "play.rectangle.fill", accentHex: "FF0000"),
        BlockedApp(id: "reddit", name: "Reddit", bundleIdentifier: "com.reddit.Reddit", iconSystemName: "text.bubble.fill", accentHex: "FF4500"),
    ]
}