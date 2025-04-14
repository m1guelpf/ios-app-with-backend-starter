import Foundation
import AuthenticationServices

final class SignInWithApple: NSObject {
	private var continuation: CheckedContinuation<Result<ASAuthorization, any Error>, Never>? = nil

	func run() async -> Result<ASAuthorization, any Error> {
		let appleIDProvider = ASAuthorizationAppleIDProvider()
		let request = appleIDProvider.createRequest()
		request.requestedScopes = [.email]
		request.requestedOperation = .operationLogin

		let authorizationController = ASAuthorizationController(authorizationRequests: [request])
		authorizationController.delegate = self
		authorizationController.presentationContextProvider = self
		authorizationController.performRequests()

		return await withCheckedContinuation { continuation = $0 }
	}
}

extension SignInWithApple: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
	func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: any Error) {
		continuation?.resume(returning: .failure(error))
	}

	func authorizationController(controller _: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		continuation?.resume(returning: .success(authorization))
	}

	func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
		guard let scene = UIApplication.shared.connectedScenes.first,
		      let sceneDelegate = scene.delegate as? UIWindowSceneDelegate,
		      let window = sceneDelegate.window,
		      let window else { fatalError("No window found in SignInWithApple") }

		return window
	}
}
