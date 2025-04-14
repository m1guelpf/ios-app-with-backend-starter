/// Call the given Closure with the given value then return the value.
func tap<T>(_ value: T, _ block: (T) -> Void) -> T {
	block(value)
	return value
}

/// Call the given Closure with the given value then return the result.
func with<T, R>(_ value: T, _ block: (inout T) -> R) -> R {
	var copy = value
	return block(&copy)
}
