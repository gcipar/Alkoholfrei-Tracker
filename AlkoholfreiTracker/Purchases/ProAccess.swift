import Foundation

enum ProAccess {
    static let debugKey = "debug.pro.enabled"

    static var isPro: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: debugKey)
        #else
        false
        #endif
    }
}
