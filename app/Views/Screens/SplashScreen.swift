import Device
import SwiftUI
import AuthenticationServices

struct SplashScreen: View {
	@Environment(API.self) private var api
	@Environment(\.colorScheme) var currentScheme

	var body: some View {
		VStack {
			Spacer()

			Text("Welcome to {{NAME}}")
				.font(.largeTitle)
				.bold()

			Spacer()

			Button(action: signIn) {
				Text("Sign in")
					.foregroundStyle(.primary)
					.fontWeight(.medium)
					.frame(maxWidth: .infinity, maxHeight: 50)
					.background(.thickMaterial)
					.clipShape(.rect(cornerRadius: 12))
					.padding()
			}
			.foregroundStyle(.primary)
		}
	}

	func signIn() {
		Task {
			let result = await SignInWithApple().run()

			guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential else {
				return
			}

			guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
				return
			}

			do {
				try await api.signIn(with: idToken, from: Device.current.device.officialName)
			} catch {
				print("Failed to sign in: \(error)")
			}
		}
	}
}

#Preview {
	SplashScreen()
		.environment(API())
}
