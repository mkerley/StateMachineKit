#  StateMachineKit
A reusable state machine imlemented in Swift.

A basic state machine. Requires you to provide:
1. A set of states (typically an enum)
2. A set of events (typically an enum)
3. An initial state
4. Allowable transitions between states (i.e. given state `X` and event `Y`, move to state `Z`)
5. (Optional) Handlers to run when entering or exiting specific states

Here's a minimal example:

```swift
enum State {
  case foo, bar
}

enum Event {
  case go
}

let machine = StateMachine<State, Event>(state: .foo) { config in
  config.transition(from: .foo, on: .go, to: .bar)
  config.onExit(.foo) { print("Bye foo") }
  config.onEnter(.bar) { print("Hello bar") }
}
```

This creates a machine in `foo` state
Once the machine is defined, you can feed it events:

```
machine.handle(.go)
```

Here's a more practical example (also available in `StateMachineLoginExample/main.swift`).

```swift
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
// Output: Logging in...

machine.handle(.loginFail)    // Maybe user entered the wrong password
// Output: Login failed!

machine.handle(.startLogin)   // Trying again
// Output: Logging in...

machine.handle(.loginSuccess) // Yay!
// Output: Login successful!

machine.handle(.logout)       // All done
// Output: Logged out.
```
