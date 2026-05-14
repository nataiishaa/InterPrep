import Foundation

extension SimpleResumeUploadView {
    struct Model {
        let isLoading: Bool
        let onUpload: () -> Void
        let onSkip: () -> Void
    }
}
