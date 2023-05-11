//
//  SimpleStateMachine.swift
//  ButterflyMXSDK
//
//  Created by Zhe Cui on 10/10/18.
//  Ref: https://github.com/JessicaIp/SimpleStateMachine
//  Copyright © 2018 ButterflyMX. All rights reserved.
//

class SimpleStateMachine<State, Event> where State: Hashable, Event: Hashable {
    public private(set) var currentState: State
    private var states: [State : [Event : State]] = [:]
    
    // MARK: - Init
    public init(initialState: State) {
        currentState = initialState
    }
    
    public subscript(state: State) -> [Event : State]? {
        get {
            return states[state]
        }
        set(transitions) {
            states[state] = transitions
        }
    }
    
    public subscript(event: Event) -> State? {
        if let transitions = states[currentState] {
            if let nextState = transitions[event] {
                return nextState
            }
        }
        return nil
    }
    
    public func transition(_ event: Event) -> State? {
        if let nextState = self[event] {
            currentState = nextState
            return nextState
        }
        
        return nil
    }
}
