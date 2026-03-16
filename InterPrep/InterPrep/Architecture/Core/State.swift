//
//  State.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation

public enum Message<Input, Feedback> {
    case input(Input)
    case feedback(Feedback)
}

/// Protocol for State management
public protocol FeatureState {
    associatedtype Input
    associatedtype Feedback
    associatedtype Effect
    
    @MainActor
    static func reduce(
        state: inout Self,
        with message: Message<Input, Feedback>
    ) -> Effect?
}
