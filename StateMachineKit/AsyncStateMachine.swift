//
//  AsyncStateMachine.swift
//  StateMachineKit
//
//  Created by Michael Kerley on 10/1/17.
//  Copyright © 2017 Michael Kerley. All rights reserved.
//

import Foundation

/// A state machine that queues all state changes. This enforces in-order processing
/// and helps clients avoid race conditions.
///
/// The tradeoff is that calls to handle(event:) return asynchronously.
/// An optional completion handler is provided to compensate for this.
open class AsyncStateMachine<State: Hashable, Event: Hashable>: StateMachine<State, Event> {
	private let eventQueue: OperationQueue = {
		let q = OperationQueue()
		q.maxConcurrentOperationCount = 1
		return q
	}()

	override open func handle(_ event: Event) {
		eventQueue.addOperation { [weak self] in
			self?.process(event)
		}
	}

	public func handle(_ event: Event, completionHandler: @escaping () -> Void) {
		eventQueue.addOperation { [weak self] in
			self?.process(event)
			completionHandler()
		}
	}

	private func process(_ event: Event) {
		super.handle(event)
	}
}
