//
//  Store.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation
import Combine

@MainActor
public final class Store<S: FeatureState, EH: EffectHandler>: ObservableObject where EH.S == S {
    @Published public private(set) var state: S
    
    private let effectHandler: EH
    private var effectTask: Task<Void, Never>?
    
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
    
    public func send(_ input: S.Input) {
        process(message: .input(input))
    }
    
    private func process(message: Message<S.Input, S.Feedback>) {
        let effect = S.reduce(state: &state, with: message)
        
        guard let effect = effect else { return }
        
        effectTask?.cancel()
        effectTask = Task { [weak self] in
            guard let self = self else { return }
            
            let feedback = await self.effectHandler.handle(effect: effect)
            
            guard !Task.isCancelled, let feedback = feedback else { return }
            
            await MainActor.run {
                self.process(message: .feedback(feedback))
            }
        }
    }
    
    deinit {
        effectTask?.cancel()
    }
}
