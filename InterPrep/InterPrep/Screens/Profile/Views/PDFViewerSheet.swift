//
//  PDFViewerSheet.swift
//  InterPrep
//
//  PDF viewer sheet
//

import PDFKit
import SwiftUI

struct PDFViewerSheet: View {
    let pdfURL: URL
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PDFKitView(url: pdfURL)
                .navigationTitle("Резюме")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Готово") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        ShareLink(item: pdfURL) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

#Preview {
    PDFViewerSheet(pdfURL: URL(fileURLWithPath: "/tmp/resume.pdf"))
}
