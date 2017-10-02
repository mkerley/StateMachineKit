//
//  StateMachine.swift
//  StateMachineKit
//
//  Created by Michael Kerley on 9/30/17.
//  Copyright © 2017 Michael Kerley. All rights reserved.
//

import Foundation

/// A basic state machine. Requires you to provide:
/// 1. A set of states (typically an enum)
/// 2. A set of events (typically an enum)
/// 3. An initial state
/// 4. Allowable transitions between states (i.e. given state `X` and event `Y`, move to state `Z`)
/// 5. (Optional) Handlers to run when entering or exiting specific states
///
/// Here's a minimal example:
/// ````
/// import StateMachineKit
///
/// enum State {
///   case foo, bar
/// }
///
/// enum Event {
///   case go
/// }
///
/// let machine = StateMachine<State, Event>(state: .foo) { config in
///   config.transition(from: .foo, on: .go, to: .bar)
///   config.onExit(.foo) { print("Bye foo") }
///   config.onEnter(.bar) { print("Hello bar") }
/// }
/// ````
///
/// This creates a machine in "foo" state
///
/// Once the machine is defined, you can feed it events:
/// ````
/// machine.handle(.go)
/// ````
///
open class StateMachine<State: Hashable, Event: Hashable> {
	typealias TransitionMap = [Event: State]
    typealias StateTransitionMap = [State: TransitionMap]
	typealias StateActionMap = [State: (State, State) -> Void]
	public typealias ChangeHandler = (_ old: State, _ new: State, _ event: Event) -> Void

	public class Config {
		fileprivate var transitions: StateTransitionMap = [:]
		fileprivate var defaultTransitions: TransitionMap = [:]
		fileprivate var onExit: StateActionMap = [:]
		fileprivate var onEnter: StateActionMap = [:]
		fileprivate var onChange: ChangeHandler?

		public func transition(from oldState: State, on event: Event, to newState: State) {
			var oldStateHandler = transitions[oldState]
			if oldStateHandler == nil {
				oldStateHandler = [:]
			}
			oldStateHandler![event] = newState
			transitions[oldState] = oldStateHandler
		}

		public func transitionFromAny(on event: Event, to newState: State) {
			defaultTransitions[event] = newState
		}

		public func onExit(_ state: State, handler: @escaping () -> Void) {
			onExit[state] = { _, _ in handler() }
		}

		public func onExit(_ state: State, handler: @escaping (_ old: State, _ new: State) -> Void) {
			onExit[state] = handler
		}

		public func onEnter(_ state: State, handler: @escaping () -> Void) {
			onEnter[state] = { _, _ in handler() }
		}

		public func onEnter(_ state: State, handler: @escaping (_ old: State, _ new: State) -> Void) {
			onEnter[state] = handler
		}

		public func onChange(handler: @escaping ChangeHandler) {
			onChange = handler
		}
	}
    
    private (set) var state: State
    
    private let transitions: StateTransitionMap
	private let defaultTransitions: TransitionMap
	private let onExit: StateActionMap
	private let onEnter: StateActionMap
	private let onChange: ChangeHandler?

	public init(state: State, configClosure: (_ config: Config) -> Void) {
		let config = Config()
		configClosure(config)

		self.state = state
		self.transitions = config.transitions
		self.defaultTransitions = config.defaultTransitions
		self.onExit = config.onExit
		self.onEnter = config.onEnter
		self.onChange = config.onChange
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

		onChange?(oldState, newState, event)
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
