import Foundation

#if os(iOS)
import UIKit
import AudioToolbox
#endif

// MARK: - Feedback Service
// Optional haptics and a soft system sound for satisfying moments. Everything
// is guarded so the library still builds on macOS.

@MainActor
enum FeedbackService {
    private static var hapticsEnabled: Bool {
        if UserDefaults.standard.object(forKey: "vault.haptics") == nil { return true }
        return UserDefaults.standard.bool(forKey: "vault.haptics")
    }

    private static var soundEnabled: Bool {
        if UserDefaults.standard.object(forKey: "vault.sounds") == nil { return true }
        return UserDefaults.standard.bool(forKey: "vault.sounds")
    }

    static func tap() {
        #if os(iOS)
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    static func success() {
        #if os(iOS)
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func warning() {
        #if os(iOS)
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        #endif
    }

    static func deposit() {
        success()
        #if os(iOS)
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(1104)
        #endif
    }
}
