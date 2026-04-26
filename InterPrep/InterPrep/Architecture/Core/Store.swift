//
//  Store.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
@dynamicMemberLookup
public final class Store<S: FeatureState, EH: EffectHandler> where EH.StateType == S {
    public private(set) var state: S
    public let effectHandler: EH
    
    private nonisolated(unsafe) var tasks: [Task<Void, Error>] = []
    private nonisolated(unsafe) var debouncingContainer: AnyObject?
    
    public init(
        state: S,
        effectHandler: EH
    ) {
        self.state = state
        self.effectHandler = effectHandler
    }
    
    public convenience init(state: S) where EH == DummyEffectHandler<S> {
        self.init(state: state, effectHandler: DummyEffectHandler())
    }
    
    deinit {
        tasks.forEach { $0.cancel() }
    }
    
    public subscript<Value>(dynamicMember keyPath: KeyPath<S, Value>) -> Value {
        state[keyPath: keyPath]
    }
    
    public func send(_ input: S.Input) {
        send(.input(input))
    }
    
    private func send(_ message: Message<S.Input, S.Feedback>) {
        guard let effect = updateState(with: message) else { return }
        handle(effect)
    }
    
    func updateState(with message: Message<S.Input, S.Feedback>) -> S.Effect? {
        S.reduce(state: &state, with: message)
    }
    
    private func handle(_ effect: S.Effect) {
        let task = Task {
            guard let feedback = await effectHandler.handle(effect: effect) else { return }
            try Task.checkCancellation()
            await MainActor.run { [weak self] in
                self?.send(.feedback(feedback))
            }
        }
        tasks.append(task)
    }
}

// MARK: - Debouncing

public extension Store where S.Input: Hashable {
    private func getOrCreateDebouncingContainer() -> DebouncingContainer<S.Input> {
        if let container = debouncingContainer as? DebouncingContainer<S.Input> {
            return container
        }
        let container = DebouncingContainer<S.Input>()
        debouncingContainer = container
        return container
    }
    
    func send(
        debouncing input: S.Input,
        with debouncingPolicy: DebouncingPolicy
    ) {
        guard let effect = updateState(with: .input(input)) else { return }
        
        getOrCreateDebouncingContainer().debounce(
            value: input,
            with: debouncingPolicy,
            action: { [weak self] in
                await self?.handle(effect)
            }
        )
    }
}

// MARK: - Bindings

public extension Store {
    func binding<Value>(
        get keyPath: KeyPath<S, Value>,
        set input: @escaping (Value) -> S.Input
    ) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.send(input($0)) }
        )
    }
    
    func binding<Value>(
        get keyPath: KeyPath<S, Value>,
        set input: @escaping (Value) -> S.Input,
        debouncingPolicy: DebouncingPolicy
    ) -> Binding<Value> where S.Input: Hashable {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.send(debouncing: input($0), with: debouncingPolicy) }
        )
    }
}

// MARK: - Debouncing Support

public struct DebouncingPolicy: Sendable {
    public let duration: Duration
    
    public init(duration: Duration) {
        self.duration = duration
    }
    
    public static func seconds(_ seconds: Double) -> DebouncingPolicy {
        DebouncingPolicy(duration: .milliseconds(Int(seconds * 1000)))
    }
    
    public static func milliseconds(_ ms: Int) -> DebouncingPolicy {
        DebouncingPolicy(duration: .milliseconds(ms))
    }
}

@MainActor
final class DebouncingContainer<Input: Hashable>: @unchecked Sendable {
    private var tasks: [Input: Task<Void, Never>] = [:]
    
    func debounce(
        value: Input,
        with policy: DebouncingPolicy,
        action: @escaping @Sendable () async -> Void
    ) {
        tasks[value]?.cancel()
        
        tasks[value] = Task {
            try? await Task.sleep(for: policy.duration)
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}
