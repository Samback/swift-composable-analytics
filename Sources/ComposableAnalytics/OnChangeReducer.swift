import Foundation
import ComposableArchitecture

extension Reducer {
	@inlinable
	public func analyticsOnChange<V: Equatable>(
		of toValue: @escaping (State) -> V,
		_ toAnalyticsData: @escaping (V, V) -> AnalyticsData
	) -> _OnChangeAnalyticsReducer<Self, V> {
		_OnChangeAnalyticsReducer(base: self, toValue: toValue, isDuplicate: ==, toAnalyticsData: toAnalyticsData)
	}
}

@Reducer
public struct _OnChangeAnalyticsReducer<Base: Reducer, Value: Equatable> {
	public typealias State = Base.State
	public typealias Action = Base.Action
	
	@usableFromInline
	let base: Base

	@usableFromInline
	let toValue: (Base.State) -> Value

	@usableFromInline
	let isDuplicate: (Value, Value) -> Bool

	@usableFromInline
	@Dependency(\.analyticsClient) var analyticsClient

	@usableFromInline
	let toAnalyticsData: (Value, Value) -> AnalyticsData

	@usableFromInline
	init(
		base: Base,
		toValue: @escaping (Base.State) -> Value,
		isDuplicate: @escaping (Value, Value) -> Bool,
		toAnalyticsData: @escaping (Value, Value) -> AnalyticsData
	) {
		self.base = base
		self.toValue = toValue
		self.isDuplicate = isDuplicate
		self.toAnalyticsData = toAnalyticsData
	}

	public var body: some ReducerOf<Self> {
		Reduce { state, action in
			let oldValue = toValue(state)
			let effects = self.base.reduce(into: &state, action: action)
			let newValue = toValue(state)

			return isDuplicate(oldValue, newValue)
			? effects
			: effects.merge(with: .run { _ in analyticsClient.sendAnalytics(toAnalyticsData(oldValue, newValue)) })
		}
	}
}
