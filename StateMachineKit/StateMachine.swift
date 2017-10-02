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
    
    private let transitions: StateTransitionMap
	private let defaultTransitions: TransitionMap
	private let onExit: StateActionMap
	private let onEnter: StateActionMap

    init(state: State, configClosure: (_ config: Config) -> Void) {
		let config = Config()
		configClosure(config)

		self.state = state
		self.transitions = config.transitions
		self.defaultTransitions = config.defaultTransitions
		self.onExit = config.onExit
		self.onEnter = config.onEnter
	}
    
    open func handle(_ event: Event) {
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
    
    private func state(for event: Event) -> State {
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

/// A state machine that queues all state changes. This enforces in-order processing
/// and helps clients avoid race conditions.
///
/// The tradeoff is that calls to handle(event:) return asynchronously.
/// An optional completion handler is provided to compensate for this.
class AsyncStateMachine<State: Hashable, Event: Hashable>: StateMachine<State, Event> {
	private let eventQueue: OperationQueue = {
		let q = OperationQueue()
		q.maxConcurrentOperationCount = 1
		return q
	}()

	override func handle(_ event: Event) {
		eventQueue.addOperation { [weak self] in
			self?.process(event)
		}
	}

	func handle(_ event: Event, completionHandler: @escaping () -> Void) {
		eventQueue.addOperation { [weak self] in
			self?.process(event)
			completionHandler()
		}
	}

	private func process(_ event: Event) {
		super.handle(event)
	}
}
