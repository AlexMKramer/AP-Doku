import Foundation
import UIKit

class PopupManager {
    static let shared = PopupManager()
    
    func showPopup(message: String, title: String) {
        // Implement your popup logic here.
        // For example, if using UIKit, present a UIAlertController.
        print("Popup - \(title): \(message)")
    }
}
