import XCTest
@testable import ComposableAnalytics

final class AnalyticsClientTests: XCTestCase {
	
	func testAnalyticsClientSendsAnalytics() {
		var receivedAnalytics: AnalyticsData?
		
		let client = AnalyticsClient { analytics in
			receivedAnalytics = analytics
		}
		
		let testAnalytics = AnalyticsData.event(name: "test_event")
		client.sendAnalytics(testAnalytics)
		
		XCTAssertEqual(receivedAnalytics, testAnalytics)
	}
	
	func testAnalyticsClientMerge() {
		var client1Analytics: [AnalyticsData] = []
		var client2Analytics: [AnalyticsData] = []
		var client3Analytics: [AnalyticsData] = []
		
		let client1 = AnalyticsClient { analytics in
			client1Analytics.append(analytics)
		}
		
		let client2 = AnalyticsClient { analytics in
			client2Analytics.append(analytics)
		}
		
		let client3 = AnalyticsClient { analytics in
			client3Analytics.append(analytics)
		}
		
		let mergedClient = AnalyticsClient.merge(client1, client2, client3)
		
		let testAnalytics = AnalyticsData.event(name: "merged_event")
		mergedClient.sendAnalytics(testAnalytics)
		
		XCTAssertEqual(client1Analytics, [testAnalytics])
		XCTAssertEqual(client2Analytics, [testAnalytics])
		XCTAssertEqual(client3Analytics, [testAnalytics])
	}
	
	func testAnalyticsClientMergeWithSingleClient() {
		var receivedAnalytics: [AnalyticsData] = []
		
		let client = AnalyticsClient { analytics in
			receivedAnalytics.append(analytics)
		}
		
		let mergedClient = AnalyticsClient.merge(client)
		
		let testAnalytics = AnalyticsData.screen(name: "TestScreen")
		mergedClient.sendAnalytics(testAnalytics)
		
		XCTAssertEqual(receivedAnalytics, [testAnalytics])
	}
	
	func testAnalyticsClientMergeWithEmptyClients() {
		let mergedClient = AnalyticsClient.merge()
		
		// Should not crash when no clients are provided
		let testAnalytics = AnalyticsData.userId("test_user")
		mergedClient.sendAnalytics(testAnalytics)
		
		// Test passes if no crash occurs
		XCTAssertTrue(true)
	}
	
	func testConsoleLoggerClient() {
		// Test that console logger doesn't crash
		let consoleClient = AnalyticsClient.consoleLogger
		let testAnalytics = AnalyticsData.event(name: "console_test")
		
		// Should not crash
		consoleClient.sendAnalytics(testAnalytics)
		
		// Test passes if no crash occurs
		XCTAssertTrue(true)
	}
	
	func testUnimplementedClient() {
		let unimplementedClient = AnalyticsClient.unimplemented
		let testAnalytics = AnalyticsData.event(name: "unimplemented_test")
		
		// The unimplemented client should report the issue
		// We expect this to trigger an assertion in debug builds
		XCTExpectFailure("Unimplemented analytics client should fail") {
			unimplementedClient.sendAnalytics(testAnalytics)
		}
	}
} 