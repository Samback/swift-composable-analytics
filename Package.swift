// swift-tools-version: 5.9

import PackageDescription

let package = Package(
	name: "swift-composable-analytics",
	platforms: [
		.iOS(.v16),
		.macOS(.v13),
		.tvOS(.v16),
		.watchOS(.v9),
	],
	products: [
		.library(name: "ComposableAnalytics", targets: ["ComposableAnalytics"]),
	],
	dependencies: [
		.package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.9.0"),
	],
	targets: [
		.target(
			name: "ComposableAnalytics",
			dependencies: [
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
			]
		),
		.testTarget(
			name: "ComposableAnalyticsTests",
			dependencies: [
				"ComposableAnalytics",
				.product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
			]
		)
	]
)
