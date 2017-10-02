//
//  AsyncStateMachineTests.swift
//  StateMachineKitTests
//
//  Created by Michael Kerley on 10/1/17.
//  Copyright © 2017 Michael Kerley. All rights reserved.
//

import XCTest
@testable import StateMachineKit

class AsyncStateMachineTests: XCTestCase {
	
	func testNetworkLoginSuccess() {
		let expect = expectation(description: "should succeed")

		let login = LoginFixture { state in
			XCTAssertEqual(state, .loggedIn)
			expect.fulfill()
		}

		login.simulateLogin(result: .loginSuccess)
		waitForExpectations(timeout: 3, handler: nil)
	}

	func testNetworkLoginFailure() {
		let expect = expectation(description: "should fail")

		let login = LoginFixture { state in
			XCTAssertEqual(state, .loggedOut)
			expect.fulfill()
		}

		login.simulateLogin(result: .loginFail)
		waitForExpectations(timeout: 3, handler: nil)
	}

	func testNetworkLoginError() {
		let expect = expectation(description: "should error")

		let login = LoginFixture { state in
			XCTAssertEqual(state, .loggedOut)
			expect.fulfill()
		}

		login.simulateLogin(result: .networkError)
		waitForExpectations(timeout: 3, handler: nil)
	}

	func testBasicAsyncMachine() {
		enum State {
			case foo, bar
		}

		enum Event {
			case go
		}

		let sm = AsyncStateMachine<State, Event>(state: .foo) { config in
			config.transition(from: .foo, on: .go, to: .bar)
		}

		let expect = expectation(description: "should go to bar")

		XCTAssertEqual(sm.state, State.foo)
		sm.handle(.go) {
			XCTAssertEqual(sm.state, State.bar)
			expect.fulfill()
		}
		waitForExpectations(timeout: 1, handler: nil)
	}

	func testAsyncMachineShouldHandleOneEventAtATime() {
		enum State {
			case a, b, c
		}

		enum Event {
			case aToB, bToC, aToC
		}

		var sm: AsyncStateMachine<State, Event>!

		let expect = expectation(description: "should handle aToB and ignore aToC")

		var count = 0
		let onExitA = {
			// The normal/sync machine will go into an infinite loop on this test.
			// This counter escapes the loop and lets the test fail quickly.
			if count > 0 {
				XCTFail("Should not attempt to handle simultaneous events")
				return
			}
			count += 1
			sm.handle(.aToC) {
				// By the time this queued event gets handled, we'll be in state b,
				// and aToC should be ignored
				XCTAssertEqual(sm.state, .b)
				expect.fulfill()
			}
		}

		sm = AsyncStateMachine<State, Event>(state: .a) {
			$0.transition(from: .a, on: .aToB, to: .b)
			$0.transition(from: .b, on: .bToC, to: .c)
			$0.transition(from: .a, on: .aToC, to: .c)

			$0.onExit(.a, handler: onExitA)
		}

		XCTAssertEqual(sm.state, .a)
		sm.handle(.aToB)
		waitForExpectations(timeout: 1, handler: nil)
	}
}

class LoginFixture {
	enum State {
		case loggedOut
		case loggingIn
		case loggedIn
	}

	enum Event {
		case sendLoginRequest
		case networkError
		case loginSuccess
		case loginFail
	}

	lazy var stateMachine: AsyncStateMachine<State, Event> = {
		let sm = AsyncStateMachine<State, Event>(state: .loggedOut) {
			$0.transition(from: .loggedOut, on: .sendLoginRequest, to: .loggingIn)

			$0.transition(from: .loggingIn, on: .networkError, to: .loggedOut)
			$0.transition(from: .loggingIn, on: .loginFail, to: .loggedOut)

			$0.transition(from: .loggingIn, on: .loginSuccess, to: .loggedIn)

			$0.onExit(.loggingIn) { _, resultState in self.loginDidFinish?(resultState) }
		}

		return sm
	}()

	var loginDidFinish: ((State) -> Void)?

	init(loginDidFinish: @escaping (State) -> Void) {
		self.loginDidFinish = loginDidFinish
	}

	func simulateLogin(result: Event) {
		stateMachine.handle(.sendLoginRequest)

		DispatchQueue.global(qos: .background).async {
			self.stateMachine.handle(result)
		}
	}
}
