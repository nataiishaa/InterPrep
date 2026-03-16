//
//  ResumeUploadViewSnapshotTests.swift
//  ResumeUploadFeatureTests
//
//  Snapshot tests for ResumeUploadView
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import ResumeUploadFeature

final class ResumeUploadViewSnapshotTests: SnapshotTestCase {

    // MARK: - Tests
    
    func testResumeUploadView_idle() {
        let view = ResumeUploadView(model: .idle)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "idle"
        )
    }
    
    func testResumeUploadView_withFile() {
        let view = ResumeUploadView(model: .withFile)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "withFile"
        )
    }
    
    func testResumeUploadView_uploading() {
        let view = ResumeUploadView(model: .uploading)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "uploading"
        )
    }
    
    func testResumeUploadView_success() {
        let view = ResumeUploadView(model: .success)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "success"
        )
    }
    
    func testResumeUploadView_error() {
        let view = ResumeUploadView(model: .error)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "error"
        )
    }
    
    func testResumeUploadView_uploadingProgress() {
        let view = ResumeUploadView(model: .fixture(
            uploadStatus: .uploading,
            selectedFile: .init(
                name: "my_resume.pdf",
                size: 2_500_000,
                url: URL(fileURLWithPath: "/tmp/my_resume.pdf"),
                type: .pdf
            ),
            uploadProgress: 0.75
        ))
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "uploadingProgress75"
        )
    }
    
    func testResumeUploadView_iPhone14Pro() {
        let view = ResumeUploadView(model: .idle)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhone13Pro),
            named: "iPhone14Pro"
        )
    }
    
    func testResumeUploadView_iPhoneSE() {
        let view = ResumeUploadView(model: .idle)
        let hostingController = UIHostingController(rootView: view)
        
        assertSnapshot(
            of: hostingController,
            as: .image(on: .iPhoneSe),
            named: "iPhoneSE"
        )
    }
}
