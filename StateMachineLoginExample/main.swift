//
//  main.swift
//  StateMachineLoginExample
//
//  Created by Michael Kerley on 10/1/17.
//  Copyright © 2017 Michael Kerley. All rights reserved.
//

import Foundation

// Note: In a normal app, you'd "import StateMachineKit".
// But since command-line utils are sort of special, I'm statically linking to the necessary classes.

enum LoginState {
	case loggedOut, loggingIn, loggedIn
}

enum LoginEvent {
	case startLogin, loginSuccess, loginFail, logout
}

let machine = StateMachine<LoginState, LoginEvent>(state: .loggedOut) { config in
	config.transition(from: .loggedOut, on: .startLogin, to: .loggingIn)
	config.transition(from: .loggingIn, on: .loginSuccess, to: .loggedIn)
	config.transition(from: .loggingIn, on: .loginFail, to: .loggedOut)
	config.transition(from: .loggedIn, on: .logout, to: .loggedOut)

	config.onEnter(.loggingIn) {
		print("Logging in...")
	}

	config.onEnter(.loggedIn) {
		print("Login successful!")
	}

	config.onEnter(.loggedOut) { oldState, newState in
		if oldState == .loggingIn {
			print("Login failed!")
		} else {
			print("Logged out.")
		}
	}
}

// Now the machine is defined and ready to use.

machine.handle(.startLogin)   // User entered their credentials
machine.handle(.loginFail)    // Maybe user entered the wrong password
machine.handle(.startLogin)   // Trying again
machine.handle(.loginSuccess) // Yay!
machine.handle(.logout)       // All done
