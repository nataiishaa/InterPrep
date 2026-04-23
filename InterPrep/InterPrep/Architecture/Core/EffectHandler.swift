//
//  EffectHandler.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation

public protocol EffectHandler<StateType>: Actor {
    associatedtype StateType: FeatureState
    func handle(effect: StateType.Effect) async -> StateType.Feedback?
}

public final actor DummyEffectHandler<StateType: FeatureState>: EffectHandler {
    public init() {}
    
    public func handle(effect: StateType.Effect) async -> StateType.Feedback? {
        return nil
    }
}
