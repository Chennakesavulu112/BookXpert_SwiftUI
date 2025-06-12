import SwiftUI

struct DeleteBannerView: View {
    let productName: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "trash.fill")
                .foregroundColor(.red)
            
            Text("\(productName) has been deleted")
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red, lineWidth: 1)
        )
        .shadow(radius: 2)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
} 