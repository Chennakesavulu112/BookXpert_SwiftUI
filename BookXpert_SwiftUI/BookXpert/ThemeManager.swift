import SwiftUI

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}

// Extension to get the current color scheme
extension ColorScheme {
    static var current: ColorScheme {
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        return isDarkMode ? .dark : .light
    }
} 