//
//  Store.swift
//  InterPrep
//
//  Created by Architecture Core
//

import Foundation
import Combine

/*
 
 STORE - REDUX-LIKE ХРАНИЛИЩЕ
 
 Это связующее звено между UI и бизнес-логикой:
 - Хранит State (состояние экрана)
 - Принимает Input от UI через метод send()
 - Вызывает State.reduce() для обновления состояния
 - Передаёт Effect в EffectHandler
 - Получает Feedback и снова обновляет State
 
 Использование:
 1. Создаём Store в Container или AppGraph
 2. Храним как @StateObject в Container
 3. Отправляем Input через store.send(.someInput)
 4. Читаем состояние через store.state
 
 Пример использования см. в Architecture/Examples/ExampleContainer.swift
 
 */

/// Redux-like Store for state management
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
    
    /// Send input to the store
    public func send(_ input: S.Input) {
        process(message: .input(input))
    }
    
    /// Process message (Input or Feedback) and handle effects
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
