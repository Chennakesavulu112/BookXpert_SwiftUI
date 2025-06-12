import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \User.timestamp, ascending: false)],
        animation: .default)
    private var users: FetchedResults<User>
    @State private var showPDF = false
    
    private let pdfURL = URL(string: "https://fssservices.bookxpert.co/GeneratedPDF/Companies/nadc/2024-2025/BalanceSheet.pdf")!
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                if let currentUser = users.first {
                    if let photoURL = currentUser.photoURL,
                       let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUser.name ?? "No Name")
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(currentUser.email ?? "No Email")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {
                    showPDF = true
                } label: {
                    Text("View PDF")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .frame(height: 30)
                }
            }
            .padding(.horizontal)
            .sheet(isPresented: $showPDF) {
                PDFView(url: pdfURL)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 
