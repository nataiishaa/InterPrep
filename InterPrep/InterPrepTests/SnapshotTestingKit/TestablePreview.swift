//
//  TestablePreview.swift
//  InterPrep
//
//  Protocol for Preview-based snapshot testing
//

import SwiftUI

@MainActor
public protocol TestablePreview: PreviewProvider {
    associatedtype Sample: View
    
    static var samples: [Sample] { get }
    static var storybookName: String { get }
}

public extension TestablePreview {
    static var previews: some View {
        ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
            sample
                .previewDisplayName("Sample \(index + 1)")
        }
    }
    
    static var storybookName: String {
        let typeName = String(describing: Self.self)
        let viewName = typeName.components(separatedBy: "_")
        return viewName.first ?? ""
    }
}
