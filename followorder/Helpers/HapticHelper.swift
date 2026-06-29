import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct HapticHelper {
    static func playNotification(type: FeedbackType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        switch type {
        case .success:
            generator.notificationOccurred(.success)
        case .warning:
            generator.notificationOccurred(.warning)
        case .error:
            generator.notificationOccurred(.error)
        }
        #endif
    }
    
    static func playImpact(style: ImpactStyle = .medium) {
        #if os(iOS)
        let systemStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light: systemStyle = .light
        case .medium: systemStyle = .medium
        case .heavy: systemStyle = .heavy
        case .rigid: systemStyle = .rigid
        case .soft: systemStyle = .soft
        }
        let generator = UIImpactFeedbackGenerator(style: systemStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
    
    enum FeedbackType {
        case success, warning, error
    }
    
    enum ImpactStyle {
        case light, medium, heavy, rigid, soft
    }
}
