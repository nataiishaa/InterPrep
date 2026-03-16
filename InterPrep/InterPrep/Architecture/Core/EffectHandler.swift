//
//  EffectHandler.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation

public protocol EffectHandler<S>: Actor {
    associatedtype S: FeatureState
    func handle(effect: S.Effect) async -> S.Feedback?
}

public final actor DummyEffectHandler<S: FeatureState>: EffectHandler {
    public init() {}
    
    public func handle(effect: S.Effect) async -> S.Feedback? {
        return nil
    }
}
