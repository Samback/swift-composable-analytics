import XCTest
@testable import ComposableAnalytics

final class AnalyticsDataTests: XCTestCase {
	
	func testAnalyticsDataEquality() {
		// Test event equality
		let event1 = AnalyticsData.event(name: "test", properties: ["key": "value"])
		let event2 = AnalyticsData.event(name: "test", properties: ["key": "value"])
		let event3 = AnalyticsData.event(name: "different", properties: ["key": "value"])
		let event4 = AnalyticsData.event(name: "test", properties: ["different": "value"])
		
		XCTAssertEqual(event1, event2)
		XCTAssertNotEqual(event1, event3)
		XCTAssertNotEqual(event1, event4)
		
		// Test screen equality
		let screen1 = AnalyticsData.screen(name: "HomeScreen")
		let screen2 = AnalyticsData.screen(name: "HomeScreen")
		let screen3 = AnalyticsData.screen(name: "SettingsScreen")
		
		XCTAssertEqual(screen1, screen2)
		XCTAssertNotEqual(screen1, screen3)
		
		// Test userId equality
		let userId1 = AnalyticsData.userId("123")
		let userId2 = AnalyticsData.userId("123")
		let userId3 = AnalyticsData.userId("456")
		
		XCTAssertEqual(userId1, userId2)
		XCTAssertNotEqual(userId1, userId3)
		
		// Test userProperty equality
		let userProp1 = AnalyticsData.userProperty(name: "age", value: "25")
		let userProp2 = AnalyticsData.userProperty(name: "age", value: "25")
		let userProp3 = AnalyticsData.userProperty(name: "age", value: "30")
		let userProp4 = AnalyticsData.userProperty(name: "name", value: "25")
		
		XCTAssertEqual(userProp1, userProp2)
		XCTAssertNotEqual(userProp1, userProp3)
		XCTAssertNotEqual(userProp1, userProp4)
		
		// Test error equality
		let error1 = AnalyticsData.error(TestError.testCase)
		let error2 = AnalyticsData.error(TestError.testCase)
		let error3 = AnalyticsData.error(TestError.anotherCase)
		
		XCTAssertEqual(error1, error2)
		XCTAssertNotEqual(error1, error3)
		
		// Test different types are not equal
		XCTAssertNotEqual(event1, screen1)
		XCTAssertNotEqual(screen1, userId1)
		XCTAssertNotEqual(userId1, userProp1)
		XCTAssertNotEqual(userProp1, error1)
	}
	
	func testExpressibleByStringLiteral() {
		let analytics: AnalyticsData = "button_tapped"
		let expectedAnalytics = AnalyticsData.event(name: "button_tapped", properties: [:])
		
		XCTAssertEqual(analytics, expectedAnalytics)
	}
	
	func testAnalyticsDataTypes() {
		// Test event with properties
		let event = AnalyticsData.event(name: "purchase", properties: [
			"item": "subscription",
			"price": "9.99"
		])
		
		if case let .event(name, properties) = event {
			XCTAssertEqual(name, "purchase")
			XCTAssertEqual(properties, ["item": "subscription", "price": "9.99"])
		} else {
			XCTFail("Expected event case")
		}
		
		// Test screen
		let screen = AnalyticsData.screen(name: "ProfileScreen")
		
		if case let .screen(name) = screen {
			XCTAssertEqual(name, "ProfileScreen")
		} else {
			XCTFail("Expected screen case")
		}
		
		// Test userId
		let userId = AnalyticsData.userId("user_123")
		
		if case let .userId(id) = userId {
			XCTAssertEqual(id, "user_123")
		} else {
			XCTFail("Expected userId case")
		}
		
		// Test userProperty
		let userProperty = AnalyticsData.userProperty(name: "subscription_tier", value: "premium")
		
		if case let .userProperty(name, value) = userProperty {
			XCTAssertEqual(name, "subscription_tier")
			XCTAssertEqual(value, "premium")
		} else {
			XCTFail("Expected userProperty case")
		}
		
		// Test error
		let error = AnalyticsData.error(TestError.testCase)
		
		if case let .error(err) = error {
			XCTAssertEqual(err.localizedDescription, TestError.testCase.localizedDescription)
		} else {
			XCTFail("Expected error case")
		}
	}
}

// MARK: - Test Helpers

enum TestError: Error, LocalizedError {
	case testCase
	case anotherCase
	
	var errorDescription: String? {
		switch self {
		case .testCase:
			return "Test error case"
		case .anotherCase:
			return "Another test error case"
		}
	}
} 