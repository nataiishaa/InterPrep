//
//  View+Snapshot.swift
//  InterPrep
//
//  Extensions for snapshot testing SwiftUI views
//

import SwiftUI
import SnapshotTesting
import XCTest

private let kSnapshotTimeout: TimeInterval = 10.0

public extension View {
    static func test<P: TestablePreview>(
        _ previewType: P.Type,
        batch: SnapshotBatch,
        precision: Float = 0.999,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) where P.Sample == Self {
        P.samples.enumerated().forEach { index, sample in
            sample.test(
                batch: batch,
                precision: precision,
                fileID: fileID,
                file: file,
                testName: "\(testName)_sample\(index)",
                line: line,
                column: column
            )
        }
    }
    
    func test(
        batch: SnapshotBatch,
        precision: Float = 0.999,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let fileUrl = URL(fileURLWithPath: "\(file)", isDirectory: false)
        let fileName = fileUrl.deletingPathExtension().lastPathComponent
        let testNameForDirectory = sanitizePathComponent(String(describing: testName))
        
        let directory = fileUrl
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(fileName)
            .appendingPathComponent(testNameForDirectory)
        
        batch.testingEnvironments.forEach { testingEnvironment in
            let failure = verifySnapshot(
                of: self,
                as: .image(
                    drawHierarchyInKeyWindow: true,
                    precision: precision,
                    perceptualPrecision: precision,
                    layout: testingEnvironment.layout,
                    traits: testingEnvironment.scheme.traitCollection
                ),
                snapshotDirectory: directory.relativePath,
                timeout: kSnapshotTimeout,
                fileID: fileID,
                file: file,
                testName: assembleTestFileName(
                    testName: testName,
                    testingEnvironment: testingEnvironment,
                    prefixToRemove: "test",
                    suffixToRemove: "Preview()"
                ),
                line: line,
                column: column
            )
            
            if let failure {
                XCTFail(
                    failure,
                    file: file,
                    line: line
                )
            }
        }
    }
}

private func sanitizePathComponent(_ string: String) -> String {
    string
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")
        .replacingOccurrences(of: " ", with: "_")
}

private func assembleTestFileName(
    testName: String,
    testingEnvironment: TestingEnvironment,
    prefixToRemove: String,
    suffixToRemove: String
) -> String {
    var name = testName
    
    if name.hasPrefix(prefixToRemove) {
        name = String(name.dropFirst(prefixToRemove.count))
    }
    
    if name.hasSuffix(suffixToRemove) {
        name = String(name.dropLast(suffixToRemove.count))
    }
    
    let components = [name] + testingEnvironment.descriptionComponents
    return components.joined(separator: "-")
}
