import XCTest
import ComposableArchitecture
@testable import ComposableAnalytics

@MainActor
final class OnChangeReducerTests: XCTestCase {
	
	func testAnalyticsOnChangeTracksStateChanges() async {
		var sentAnalytics: [AnalyticsData] = []
		
		let testStore = TestStore(initialState: TestFeatureWithOnChange.State()) {
			TestFeatureWithOnChange()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { analyticsData in
				sentAnalytics.append(analyticsData)
			})
		}
		
		await testStore.send(.incrementCount) {
			$0.count = 1
		}
		
		await testStore.send(.incrementCount) {
			$0.count = 2
		}
		
		XCTAssertEqual(sentAnalytics, [
			.event(name: "count_changed", properties: ["old_value": "0", "new_value": "1"]),
			.event(name: "count_changed", properties: ["old_value": "1", "new_value": "2"])
		])
	}
	
	func testAnalyticsOnChangeDoesNotTrackWhenValueUnchanged() async {
		var sentAnalytics: [AnalyticsData] = []
		
		let testStore = TestStore(initialState: TestFeatureWithOnChange.State(count: 5)) {
			TestFeatureWithOnChange()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { analyticsData in
				sentAnalytics.append(analyticsData)
			})
		}
		
		await testStore.send(.setCount(5)) // No change expected, so no trailing closure
		
		XCTAssertTrue(sentAnalytics.isEmpty, "No analytics should be sent when value doesn't change")
	}
	
	func testAnalyticsOnChangeWithComplexState() async {
		var sentAnalytics: [AnalyticsData] = []
		
		let testStore = TestStore(initialState: TestFeatureWithOnChange.State()) {
			TestFeatureWithOnChange()
		} withDependencies: {
			$0.analyticsClient = .init(sendAnalytics: { analyticsData in
				sentAnalytics.append(analyticsData)
			})
		}
		
		await testStore.send(.toggleFlag) {
			$0.isEnabled = true
		}
		
		await testStore.send(.setName("John")) {
			$0.name = "John"
		}
		
		XCTAssertEqual(sentAnalytics, [
			.event(name: "flag_changed", properties: ["old_value": "false", "new_value": "true"]),
			.event(name: "name_changed", properties: ["old_value": "", "new_value": "John"])
		])
	}
}

// MARK: - Test Helpers

@Reducer
struct TestFeatureWithOnChange {
	@ObservableState
	struct State: Equatable {
		var count = 0
		var isEnabled = false
		var name = ""
	}
	
	enum Action {
		case incrementCount
		case setCount(Int)
		case toggleFlag
		case setName(String)
	}
	
	var body: some ReducerOf<Self> {
		Reduce { state, action in
			switch action {
			case .incrementCount:
				state.count += 1
				return .none
			case let .setCount(value):
				state.count = value
				return .none
			case .toggleFlag:
				state.isEnabled.toggle()
				return .none
			case let .setName(name):
				state.name = name
				return .none
			}
		}
		.analyticsOnChange(of: \.count) { oldValue, newValue in
			.event(name: "count_changed", properties: [
				"old_value": String(oldValue),
				"new_value": String(newValue)
			])
		}
		.analyticsOnChange(of: \.isEnabled) { oldValue, newValue in
			.event(name: "flag_changed", properties: [
				"old_value": String(oldValue),
				"new_value": String(newValue)
			])
		}
		.analyticsOnChange(of: \.name) { oldValue, newValue in
			.event(name: "name_changed", properties: [
				"old_value": oldValue,
				"new_value": newValue
			])
		}
	}
} 