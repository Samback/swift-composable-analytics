# Composable Analytics

A composable, decoupled and testable way to add analytics to any TCA project without getting the analytics and working code tangled up together.

* [Basic Usage](#basic-usage)
* [Custom Analytics Clients](#custom-analytics-clients)
* [Testing](#testing)
* [Installation](#installation)
* [Deprecated Usage](#deprecated)

## Basic Usage

Composable Analytics provides an `AnalyticsReducer` which provides all the working logic for unwrapping and sending your analytics events to the `@Dependency(\.analyticsClient)` in your project. By default the `analyticsClient` dependency is set to `unimplemented` so first you should add the dependency to your store.

At the entry point of your app when you first create the `Store` you can update the analytics here. This package provides a `.consoleLogger` client and you can add your own too.

```swift
Store(
  initialState: App.State(),
  reducer: App()
) withDependencies: {
  $0.analyticsClient = .consoleLogger
}
```

Then in any `@Reducer` within the app you can add an `AnalyticsReducer` to the `body`. This is created with a function that takes `state` and `action` and returns an optional `AnalyticsData`.

```swift
@Reducer
struct App {
  @ObservableState
  struct State {
    var title: String
  }

  enum Action {
    case buttonTapped
  }

  var body: some ReducerOf<Self> {
    AnalyticsReducer { state, action in
      // state here is immutable so there is no way for your analytics to interfere with your app.
      switch action {
      case .buttonTapped:
        return .event(name: "AppButtonTapped", properties: ["title": state.title])
      }
    }
  
    Reduce { state, action in
      // your normal app logic sits here unchanged
      switch action {
      case .buttonTapped:
        // handle the action
        return .none
      }
    }
  }
}
```

This keeps all of your analytics out of your working code but still in a place that makes it easy to see and reason about what analytics your app is sending.

As most analytics will probably be events without any properties the `AnalyticsData` is expressible by string literal. So, `.event(name: "SomeName")` and `"SomeName"` are equivalent.

As a personal preference, I tend to use `default: return nil` at the end of it. `nil` is returned from the `AnalyticsReducer` for any action/state combination when you don't want it to send analytics. So it is a lot more convenient to wrap them all up in a `default` case at the end of the switch rather than list out all the actions and return `nil` from each.

### On Change Analytics

You can now trigger analytics from the change of state.

If your state is like...

```swift
@ObservableState
struct State {
  var count: Int
}
```

You can now add analytics when the count changes by adding a `.analyticsOnChange` to your reducer.

```swift
@Reducer
struct Feature {
  // ... State and Action definitions ...

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      // feature reducer 
      switch action {
      case .increment:
        state.count += 1
        return .none
      }
    }
    .analyticsOnChange(of: \.count) { oldValue, newValue in
      return .event(
        name: "countChanged", 
        properties: [
          "from": "\(oldValue)",
          "to": "\(newValue)",
        ]
      )
    }
  }
}
```

## Custom Analytics Clients

This package only provides an analytics client for logging to the console. Accessible as `AnalyticsClient.consoleLogger` but you can very easily add your own custom clients.

For example, you may want to log analytics to Firebase. In which case you can add your own clients by extending `AnalyticsClient`...

```swift
import Firebase
import FirebaseCrashlytics
import ComposableAnalytics

public extension AnalyticsClient {
  static var firebaseClient: Self {
    return .init(
      sendAnalytics: { analyticsData in
        switch analyticsData {
        case let .event(name: name, properties: properties):
          Firebase.Analytics.logEvent(name, parameters: properties)

        case .userId(let id):
          Firebase.Analytics.setUserID(id)
          Crashlytics.crashlytics().setUserID(id)

        case let .userProperty(name: name, value: value):
          Firebase.Analytics.setUserProperty(value, forName: name)

        case .screen(name: let name):
          Firebase.Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: name
          ])

        case .error(let error):
          Crashlytics.crashlytics().record(error: error)
        }
      }
    )
  }
}
```

This could be your Firebase implementation. Which you then add to the store by merging with any other clients you want to use...

```swift
let analytics = AnalyticsClient.merge(
  // this merges multiple analytics clients into a single instance
  .consoleLogger,
  .firebaseClient
)

Store(
  initialState: App.State(),
  reducer: App()
) withDependencies: {
  $0.analyticsClient = analytics
}
```

## Testing

This leans into the TCA way of testing. Because all your analytics are sent using Effects. This package provides an `expect` function that can be used to easily tell your test which analytics you are expecting during a test...

```swift
import XCTest
import ComposableArchitecture
@testable import App

@MainActor
class AppTests: XCTestCase {
  func testButtonTap() async throws {
    let store = TestStore(
      initialState: App.State.init(title: "Hello, world!"),
      reducer: App()
    )

    store.dependencies.analyticsClient.expect(
      .event(name: "AppButtonTapped", properties: ["title": "Hello, world!"])
    )

    await store.send(.buttonTapped)
  }
}
```

This expectation is exhaustive.

It will fail if the analytics is expected and not received. And it will fail if you receive analytics that you did not expect.

## Installation

You can add ComposableAnalytics to your project by adding `https://github.com/Samback/swift-composable-analytics` into the SPM packages for your project.

### Requirements

- iOS 16.0+ / macOS 13.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 5.9+
- TCA 1.9.0+

---

## Deprecated

### Legacy TCA Patterns (Pre-1.9.0)

<details>
<summary>Click to expand deprecated usage patterns</summary>

#### Old Reducer Declaration (Before @Reducer macro)

```swift
struct App: Reducer {
  struct State {
    var title: String
  }

  enum Action {
    case buttonTapped
  }

  var body: some ReducerOf<Self> {
    AnalyticsReducer { state, action in
      // state here is immutable so there is no way for your analytics to interfere with your app.
      switch action {
      case .buttonTapped:
        return  .event(name: "AppButtonTapped", properties: ["title": state.title])
      }
    }
  
    Reduce<State, Action> { state, action in
      // your normal app logic sits here unchanged
    }
  }
}
```

#### Old Dependency Injection Pattern

```swift
Store(
  initialState: App.State(),
  reducer: App()
    .dependency(\.analyticsClient, AnalyticsClient.consoleLogger)
)
```

#### Old Platform Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.8+
- TCA 1.0.0+

These patterns are still functional but not recommended for new projects. Consider migrating to the modern patterns shown above for better performance, type safety, and future compatibility.

</details>
