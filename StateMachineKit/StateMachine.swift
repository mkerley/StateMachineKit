//
//  StateMachine.swift
//  StateMachineKit
//
//  Created by Michael Kerley on 9/30/17.
//  Copyright © 2017 Michael Kerley. All rights reserved.
//

import Foundation

class StateMachine<State: Hashable, Event: Hashable> {
	typealias TransitionMap = [Event: State]
    typealias StateTransitionMap = [State: TransitionMap]
	typealias StateActionMap = [State: (State, State) -> Void]

	public class Config {
		fileprivate var transitions: StateTransitionMap = [:]
		fileprivate var defaultTransitions: TransitionMap = [:]
		fileprivate var onExit: StateActionMap = [:]
		fileprivate var onEnter: StateActionMap = [:]

		func transition(from oldState: State, on event: Event, to newState: State) {
			var oldStateHandler = transitions[oldState]
			if oldStateHandler == nil {
				oldStateHandler = [:]
			}
			oldStateHandler![event] = newState
			transitions[oldState] = oldStateHandler
		}

		func transitionFromAny(on event: Event, to newState: State) {
			defaultTransitions[event] = newState
		}

		func onExit(_ state: State, handler: @escaping () -> Void) {
			onExit[state] = { _, _ in handler() }
		}

		func onExit(_ state: State, handler: @escaping (_ old: State, _ new: State) -> Void) {
			onExit[state] = handler
		}

		func onEnter(_ state: State, handler: @escaping () -> Void) {
			onEnter[state] = { _, _ in handler() }
		}

		func onEnter(_ state: State, handler: @escaping (_ old: State, _ new: State) -> Void) {
			onEnter[state] = handler
		}
	}
    
    private (set) var state: State
    
    let transitions: StateTransitionMap
	let defaultTransitions: TransitionMap
	let onExit: StateActionMap
	let onEnter: StateActionMap
    
    private init(state: State, config: Config) {
		self.state = state
		self.transitions = config.transitions
		self.defaultTransitions = config.defaultTransitions
		self.onExit = config.onExit
		self.onEnter = config.onEnter
	}

	convenience init(state: State, configClosure: (_ config: Config) -> Void) {
		let config = Config()
		configClosure(config)

		self.init(state: state, config: config)
	}
    
    func handle(_ event: Event) {
        let newState = state(for: event)
        
        log(state: state, event: event, newState: newState)
        guard state != newState else {
            return
        }

		let oldState = state

		onExit[state]?(oldState, newState)
        state = newState
		onEnter[state]?(oldState, newState)
    }
    
    func state(for event: Event) -> State {
        if let handlers = transitions[state], let newState = handlers[event] {
			return newState
		}

		if let newState = defaultTransitions[event] {
			return newState
		}

		return state
    }
    
    open func log(state: State, event: Event, newState: State) {
        if state == newState {
            NSLog("\(state)[\(event)] -> no change")
        } else {
            NSLog("\(state)[\(event)] -> \(newState)")
        }
    }
}
