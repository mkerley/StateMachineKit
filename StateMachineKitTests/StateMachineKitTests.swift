//
//  StateMachineKitTests.swift
//  StateMachineKitTests
//
//  Created by Michael Kerley on 9/30/17.
//  Copyright © 2017 Michael Kerley. All rights reserved.
//

import XCTest
@testable import StateMachineKit

class StateMachineKitTests: XCTestCase {

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testBasicMachine() {
		enum State {
			case foo, bar
		}

		enum Event {
			case go
		}

		let sm = StateMachine<State, Event>(state: .foo) { config in
			config.transition(from: .foo, on: .go, to: .bar)
		}

		XCTAssertEqual(sm.state, State.foo)
		sm.handle(.go)
		XCTAssertEqual(sm.state, State.bar)
	}

	func testCatomaton() {
		enum State {
			case awake, asleep, eating, shitting, meowing
		}

		enum Event {
			case foodAvailable, ownerFellAsleep, full, tired
		}

		let cat = StateMachine<State, Event>(state: .awake) { cat in
			cat.transition(from: .awake, on: .foodAvailable, to: .eating)
			cat.transition(from: .awake, on: .ownerFellAsleep, to: .meowing)
			cat.transition(from: .awake, on: .tired, to: .asleep)

			cat.transition(from: .asleep, on: .foodAvailable, to: .eating)

			cat.transition(from: .eating, on: .full, to: .shitting)

			cat.transition(from: .meowing, on: .tired, to: .asleep)

			cat.transition(from: .shitting, on: .ownerFellAsleep, to: .meowing)
			cat.transition(from: .shitting, on: .tired, to: .asleep)

			cat.onEnter(.meowing) { NSLog("MEOW!!!") }
			cat.onEnter(.shitting) { NSLog("💩") }
		}

		XCTAssertEqual(cat.state, State.awake)
		cat.handle(.foodAvailable)
		XCTAssertEqual(cat.state, State.eating)
		cat.handle(.tired)
		XCTAssertEqual(cat.state, State.eating, "Cat should power through the lethargy and keep eating")
		cat.handle(.full)
		XCTAssertEqual(cat.state, State.shitting)
		cat.handle(.ownerFellAsleep)
		XCTAssertEqual(cat.state, State.meowing)
	}

	func testTransitionFromAny() {
		enum State {
			case foo, bar
		}

		enum Event {
			case goToBar, goToFoo
		}

		var didGoToFoo = false

		let sm = StateMachine<State, Event>(state: .foo) { sm in
			sm.transitionFromAny(on: .goToBar, to: .bar)
			sm.transitionFromAny(on: .goToFoo, to: .foo)

			sm.onEnter(.foo) { didGoToFoo = true }
		}

		XCTAssertEqual(sm.state, .foo)
		XCTAssertFalse(didGoToFoo)

		sm.handle(.goToBar)
		XCTAssertEqual(sm.state, .bar)
		XCTAssertFalse(didGoToFoo)

		sm.handle(.goToFoo)
		XCTAssertEqual(sm.state, .foo)
		XCTAssertTrue(didGoToFoo)
	}

	func testHandlersWithOldAndNewStates() {
		enum State {
			case foo, bar
		}

		enum Event {
			case goToBar, goToFoo
		}

		var didEnterFoo: (State, State)? = nil
		var didExitFoo: (State, State)? = nil

		let sm = StateMachine<State, Event>(state: .foo) { sm in
			sm.transition(from: .foo, on: .goToBar, to: .bar)
			sm.transition(from: .bar, on: .goToFoo, to: .foo)

			sm.onEnter(.foo) { old, new in didEnterFoo = (old, new) }
			sm.onExit(.foo) { old, new in didExitFoo = (old, new) }
		}

		XCTAssertEqual(sm.state, .foo)
		XCTAssertNil(didExitFoo)
		XCTAssertNil(didEnterFoo)

		sm.handle(.goToBar)
		XCTAssertEqual(sm.state, .bar)
		XCTAssertNotNil(didExitFoo)
		XCTAssertEqual(didExitFoo!.0, .foo)
		XCTAssertEqual(didExitFoo!.1, .bar)
		XCTAssertNil(didEnterFoo)

		sm.handle(.goToFoo)
		XCTAssertEqual(sm.state, .foo)
		XCTAssertNotNil(didEnterFoo)
		XCTAssertEqual(didEnterFoo!.0, .bar)
		XCTAssertEqual(didEnterFoo!.1, .foo)
	}

	func testShouldIgnoreEventsInInvalidStates() {
		enum State {
			case a, b, c
		}

		enum Event {
			case aToB, bToC
		}

		var didExitA = false

		let sm = StateMachine<State, Event>(state: .a) {
			$0.transition(from: .a, on: .aToB, to: .b)
			$0.transition(from: .b, on: .bToC, to: .c)

			$0.onExit(.a, handler: { didExitA = true })
		}

		XCTAssertEqual(sm.state, .a)

		sm.handle(.bToC)
		XCTAssertEqual(sm.state, .a)
		XCTAssertFalse(didExitA)
	}

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

	lazy var stateMachine: StateMachine<State, Event> = {
		let sm = StateMachine<State, Event>(state: .loggedOut) {
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
