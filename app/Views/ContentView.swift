import SwiftUI

struct ContentView: View {
	@Environment(API.self) var api

	var body: some View {
		VStack {
			Text("Hello, world!")
		}
		.padding()
		.task {
			do {
				try await api.checkAuthentication()
			} catch {
				print("Error: \(error)")
			}
		}
	}
}

#Preview {
	ContentView()
		.environment(API())
}
