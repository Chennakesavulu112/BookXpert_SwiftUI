import SwiftUI
import PDFKit

struct PDFView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            PDFKitView(url: url)
                .navigationBarTitle("PDF Viewer", displayMode: .inline)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFKit.PDFView {
        let pdfView = PDFKit.PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFKit.PDFView, context: Context) {
        if let document = PDFKit.PDFDocument(url: url) {
            uiView.document = document
        }
    }
}

#Preview {
    PDFView(url: URL(string: "https://fssservices.bookxpert.co/GeneratedPDF/Companies/nadc/2024-2025/BalanceSheet.pdf")!)
} 
