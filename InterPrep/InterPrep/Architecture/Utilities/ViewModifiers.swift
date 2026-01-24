//
//  ViewModifiers.swift
//  InterPrep
//
//  Useful view modifiers for the app
//

import SwiftUI

extension View {
    /// Executes action on first appear only
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(action: action))
    }
}

struct OnFirstAppearModifier: ViewModifier {
    private class AppearanceTracker: ObservableObject {
        var hasAppeared = false
    }
    
    @StateObject private var tracker = AppearanceTracker()
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content.onAppear {
            guard !tracker.hasAppeared else { return }
            tracker.hasAppeared = true
            action()
        }
    }
}
