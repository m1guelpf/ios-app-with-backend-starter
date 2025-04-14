import SwiftUI

struct AnimatePlaceholderModifier: AnimatableModifier {
	let isLoading: Bool

	@State private var isAnim: Bool = false
	private var center = (UIScreen.main.bounds.width / 2) + 110
	private let animation: Animation = .linear(duration: 1.5)

	init(isLoading: Bool) {
		self.isLoading = isLoading
	}

	func body(content: Content) -> some View {
		content.overlay(animView.mask(content))
	}

	var animView: some View {
		ZStack {
			Color.black.opacity(isLoading ? 0.09 : 0.0)

			Color.white.mask(
				Rectangle()
					.fill(LinearGradient(gradient: .init(colors: [.clear, .white.opacity(0.48), .clear]), startPoint: .top, endPoint: .bottom))
					.scaleEffect(1.5)
					.rotationEffect(.init(degrees: 70.0))
					.offset(x: isAnim ? center : -center)
			)
		}
		.animation(isLoading ? animation.repeatForever(autoreverses: false) : nil, value: isAnim)
		.onAppear {
			guard isLoading else { return }
			isAnim.toggle()
		}
		.onChange(of: isLoading) { isAnim.toggle() }
	}
}

extension View {
	func placeholder(isLoading: Bool) -> some View {
		modifier(AnimatePlaceholderModifier(isLoading: isLoading))
	}
}
