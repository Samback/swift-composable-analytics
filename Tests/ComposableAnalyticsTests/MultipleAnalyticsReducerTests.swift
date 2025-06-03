import XCTest
import ComposableArchitecture
@testable import ComposableAnalytics

@MainActor
final class MultipleAnalyticsReducerTests: XCTestCase {
	
	func testMultipleAnalyticsReducerSendsMultipleEvents() async {
		var sentAnalytics: [AnalyticsData] = []
		
		let testStore = TestStore(initialState: TestFeatureWithMultipleAnalytics.State()) {
			TestFeatureWithMultipleAnalytics()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { analyticsData in
				sentAnalytics.append(analyticsData)
			})
		}
		
		await testStore.send(.multipleAnalyticsAction) {
			$0.count += 1
		}
		
		XCTAssertEqual(sentAnalytics, [
			.event(name: "first_event"),
			.event(name: "second_event"),
			.screen(name: "test_screen")
		])
	}
	
	func testMultipleAnalyticsReducerWithNilAnalytics() async {
		let testStore = TestStore(initialState: TestFeatureWithMultipleAnalytics.State()) {
			TestFeatureWithMultipleAnalytics()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { _ in
				XCTFail("Analytics should not be sent for nil analytics data")
			})
		}
		
		await testStore.send(.noAnalyticsAction) {
			$0.count += 1
		}
	}
	
	func testMultipleAnalyticsReducerWithEmptyArray() async {
		let testStore = TestStore(initialState: TestFeatureWithMultipleAnalytics.State()) {
			TestFeatureWithMultipleAnalytics()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { _ in
				XCTFail("Analytics should not be sent for empty analytics array")
			})
		}
		
		await testStore.send(.emptyAnalyticsAction) {
			$0.count += 1
		}
	}
}

// MARK: - Test Helpers

@Reducer
struct TestFeatureWithMultipleAnalytics {
	@ObservableState
	struct State: Equatable {
		var count = 0
	}
	
	enum Action {
		case multipleAnalyticsAction
		case noAnalyticsAction
		case emptyAnalyticsAction
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .multipleAnalyticsAction, .noAnalyticsAction, .emptyAnalyticsAction:
				state.count += 1
				return .none
			}
		}
		.multipleAnalytics { state, action in
			switch action {
			case .multipleAnalyticsAction:
				return [
					.event(name: "first_event"),
					.event(name: "second_event"),
					.screen(name: "test_screen")
				]
			case .noAnalyticsAction:
				return nil
			case .emptyAnalyticsAction:
				return []
			}
		}
	}
}

// MARK: - Reducer Extension for Testing

extension Reducer {
	func multipleAnalytics(_ toAnalyticsData: @escaping (State, Action) -> [AnalyticsData]?) -> some ReducerOf<Self> {
		CombineReducers {
			self
			MultipleAnalyticsReducer(toAnalyticsData)
		}
	}
} 