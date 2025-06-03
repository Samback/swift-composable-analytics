import XCTest
import ComposableArchitecture
@testable import ComposableAnalytics

@MainActor
final class AnalyticsReducerTests: XCTestCase {
	
	func testAnalyticsReducerSendsAnalytics() async {
		let testStore = TestStore(initialState: TestState()) {
			TestFeature()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { analyticsData in
				XCTAssertEqual(analyticsData, .event(name: "test_action"))
			})
		}
		
		await testStore.send(.testAction) {
			$0.count += 1
		}
	}
	
	func testAnalyticsReducerWithNilAnalytics() async {
		let testStore = TestStore(initialState: TestState()) {
			TestFeature()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { _ in
				XCTFail("Analytics should not be sent for nil analytics data")
			})
		}
		
		await testStore.send(.actionWithoutAnalytics) {
			$0.count += 1
		}
	}
	
	func testAnalyticsReducerWithMultipleActions() async {
		var sentAnalytics: [AnalyticsData] = []
		
		let testStore = TestStore(initialState: TestState()) {
			TestFeature()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { analyticsData in
				sentAnalytics.append(analyticsData)
			})
		}
		
		await testStore.send(.testAction) {
			$0.count += 1
		}
		
		await testStore.send(.anotherTestAction) {
			$0.count += 1
		}
		
		XCTAssertEqual(sentAnalytics, [
			.event(name: "test_action"),
			.event(name: "another_test_action")
		])
	}
}

// MARK: - Test Helpers

@Reducer
struct TestFeature {
	@ObservableState
	struct State: Equatable {
		var count = 0
	}
	
	enum Action {
		case testAction
		case anotherTestAction
		case actionWithoutAnalytics
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .testAction, .anotherTestAction, .actionWithoutAnalytics:
				state.count += 1
				return .none
			}
		}
		.analytics { state, action in
			switch action {
			case .testAction:
				return .event(name: "test_action")
			case .anotherTestAction:
				return .event(name: "another_test_action")
			case .actionWithoutAnalytics:
				return nil
			}
		}
	}
}

typealias TestState = TestFeature.State

// MARK: - Reducer Extension for Testing

extension Reducer {
	func analytics(_ toAnalyticsData: @escaping (State, Action) -> AnalyticsData?) -> some ReducerOf<Self> {
		CombineReducers {
			self
			AnalyticsReducer(toAnalyticsData)
		}
	}
} 