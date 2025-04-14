import Pulse
import SwiftUI
import PulseUI
import PulseProxy

@main
struct {{NAME}}App: App {
	@State private var api: API
	@State private var isPulsePresented = false

	init() {
		NetworkLogger.enableProxy()

		let api = API()

		//        #if DEBUG
		//        try! api.useTestAuthToken()
		//        #endif

		_api = State(initialValue: api)
	}

	var body: some Scene {
		WindowGroup {
			NavigationStack {
				if !api.isAuthenticated {
					SplashScreen()
				} else {
					ContentView()
				}
			}
			.environment(api)
			.onShake { isPulsePresented = true }
			.fullScreenCover(isPresented: $isPulsePresented) {
				NavigationView {
					ConsoleView()
				}
			}
		}
	}
}
