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


#Preview {
    PDFViewerSheet(pdfURL: URL(fileURLWithPath: "/tmp/resume.pdf"))
}
