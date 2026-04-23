//
//  Store.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Combine
import Foundation

@MainActor
public final class Store<S: FeatureState, EH: EffectHandler>: ObservableObject where EH.StateType == S {
    @Published public private(set) var state: S
    
    private let effectHandler: EH
    private var effectTask: Task<Void, Never>?
    /// Счётчик «поколения» эффекта: после `await` нельзя полагаться только на `Task.isCancelled` — отмена предыдущей задачи
    /// помечает её cancelled даже если сеть уже успела вернуть ответ, и фидбек теряется → вечный `isLoading`.
    private var effectGeneration = 0
    
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
        
        effectGeneration += 1
        let generation = effectGeneration
        effectTask?.cancel()
        effectTask = Task { [weak self] in
            guard let self = self else { return }
            
            let feedback = await self.effectHandler.handle(effect: effect)
            guard let feedback else { return }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                guard generation == self.effectGeneration else { return }
                self.process(message: .feedback(feedback))
            }
        }
    }
    
    deinit {
        effectTask?.cancel()
    }
}
