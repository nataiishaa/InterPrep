//
//  SimpleResumeUploadView+Model.swift
//  InterPrep
//
//  Simple resume upload view model
//

import Foundation

extension SimpleResumeUploadView {
    struct Model {
        let isLoading: Bool
        let onUpload: () -> Void
        let onSkip: () -> Void
    }
}
