import Foundation
import UIKit

class HapticService {
    static let shared = HapticService()
    
    private init() {}
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
    
    func selection() {
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Timer-specific haptics
    
    func timerStart() {
        impact(style: .medium)
    }
    
    func timerPause() {
        impact(style: .light)
    }
    
    func timerComplete() {
        notification(type: .success)
    }
    
    func phaseTransition() {
        impact(style: .rigid)
    }
    
    func buttonTap() {
        impact(style: .light)
    }
}
