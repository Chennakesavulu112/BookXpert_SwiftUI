import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 100
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(colorScheme == .dark ? Color.black : Color.white)
                .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Book icon
            Image(systemName: "book.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size * 0.6, height: size * 0.6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        AppLogoView(size: 100)
        AppLogoView(size: 150)
        AppLogoView(size: 200)
    }
    .padding()
} 