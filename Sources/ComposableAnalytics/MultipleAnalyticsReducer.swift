import Foundation
import ComposableArchitecture

@Reducer
public struct MultipleAnalyticsReducer<State, Action> {
	public typealias State = State
	public typealias Action = Action
	
	@usableFromInline
	let toAnalyticsData: (State, Action) -> [AnalyticsData]?

	@usableFromInline
	@Dependency(\.analyticsClient) var analyticsClient

	@inlinable
	public init(_ toAnalyticsData: @escaping (State, Action) -> [AnalyticsData]?) {
		self.init(toAnalyticsData: toAnalyticsData, internal: ())
	}

	@usableFromInline
	init(toAnalyticsData: @escaping (State, Action) -> [AnalyticsData]?, internal: Void) {
		self.toAnalyticsData = toAnalyticsData
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			guard let analyticsData = toAnalyticsData(state, action) else {
				return .none
			}

			return .concatenate(
				analyticsData.map { data in
					.run { _ in analyticsClient.sendAnalytics(data) }
				}
			)
		}
	}
}
