import Foundation
import Combine

enum HintAlert: Identifiable {
    case newHint(String)
    case noMoreHints
    case hintsDisabledOnServer

    var id: String {
        switch self {
        case .newHint(let message):
            return "newHint-\(message)"
        case .noMoreHints:
            return "noMoreHints"
        case .hintsDisabledOnServer:
            return "hintsDisabledOnServer"
        }
    }
}

final class HintViewModel: ObservableObject {
    static let shared = HintViewModel()
    
    @Published var currentAlert: HintAlert? = nil
    
    private init() {}
    
    func showHint(_ hint: String) {
        DispatchQueue.main.async {
            self.currentAlert = .newHint(hint)
        }
    }
    
    func showNoMoreHints() {
        DispatchQueue.main.async {
            self.currentAlert = .noMoreHints
        }
    }
    
    func showHintsDisabledOnServer() {
        DispatchQueue.main.async {
            self.currentAlert = .hintsDisabledOnServer
        }
    }
    
    func clearAlert() {
        DispatchQueue.main.async {
            self.currentAlert = nil
        }
    }
}
