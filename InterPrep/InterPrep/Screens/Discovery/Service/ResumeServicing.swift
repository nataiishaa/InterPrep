public protocol ResumeServicing: Actor {
    func hasResume() async -> Bool
    func invalidateCache() async
}
