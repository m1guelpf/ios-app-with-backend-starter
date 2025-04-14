import Valet
import OSLog
import Foundation

fileprivate let dateFormatter = tap(ISO8601DateFormatter()) { formatter in
	formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
}

@Observable
final class API {
	var callbacks = Callbacks()

	let baseURL = URL(
		string: Bundle.main.object(forInfoDictionaryKey: "{{NAME}}BackendURL") as! String
	)!

	enum Error: Equatable, Swift.Error {
		case authenticationFailed
		case requestFailed(URLResponse)

		var localizedDescription: String {
			switch self {
				case .authenticationFailed:
					return "Authentication failed"
				case let .requestFailed(response):
					return "Request failed: \(response)"
			}
		}
	}

	private let encoder = tap(JSONEncoder()) { encoder in
		encoder.keyEncodingStrategy = .convertToSnakeCase
		encoder.dateEncodingStrategy = .custom { date, encoder in
			var container = encoder.singleValueContainer()
			try container.encode(dateFormatter.string(from: date))
		}
	}

	private let decoder = tap(JSONDecoder()) { decoder in
		decoder.keyDecodingStrategy = .convertFromSnakeCase
		decoder.dateDecodingStrategy = .custom { decoder in
			let container = try decoder.singleValueContainer()
			let string = try container.decode(String.self)
			guard let date = dateFormatter.date(from: string) else {
				throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date string: \(string)")
			}
			return date
		}
	}
}

/// API Methods
extension API {
	// Authentication

	func signIn(with identityToken: String, from deviceName: String) async throws {
		let response = try await post(baseURL.appendingPathComponent("/auth/login"), body: [
			"token": identityToken,
			"device_name": deviceName,
		], as: LoginResponse.self)

		try setAuthToken(response.token)
	}

	func checkAuthentication() async throws -> UserResponse {
		return try await get(baseURL.appendingPathComponent("/auth/user"), as: UserResponse.self)
	}

	func signOut() async throws {
		_ = try await post(baseURL.appendingPathComponent("/auth/logout"), as: String?.self, expects: 204)
		callbacks.signOut()
		try setAuthToken(nil)
	}
}

/// API Types
extension API {
	struct LoginResponse: Decodable {
		let token: String
	}

	struct UserResponse: Decodable {
		let id: String
		let email: String
		let createdAt: Date
		let updatedAt: Date
	}
}

/// Authentication Status
extension API {
	private var valet: Valet {
		Valet.valet(with: Identifier(nonEmpty: "{{BUNDLE_PREFIX}}.{{NAME}}")!, accessibility: .whenUnlocked)
	}

	private var authToken: String? {
		_$observationRegistrar.access(self, keyPath: \.authToken)

		do {
			return try valet.string(forKey: "authToken")
		} catch {
			if error != .itemNotFound {
				Logger.app.error("Failed to read authToken from keychain: \(error.localizedDescription)")
			}

			return nil
		}
	}

	public var isAuthenticated: Bool {
		authToken != nil
	}

	private func setAuthToken(_ authToken: String?) throws {
		try _$observationRegistrar.withMutation(of: self, keyPath: \.authToken) {
			if let authToken {
				try valet.setString(authToken, forKey: "authToken")
			} else {
				try valet.removeObject(forKey: "authToken")
			}
		}
	}

	#if DEBUG
	func useTestAuthToken() throws {
		try setAuthToken("test-token2")
	}
	#endif
}

/// HTTP Requests
extension API {
	private func get<T: Decodable>(_ url: URL, headers: [String: String] = [:], as _: T.Type, expects statusCode: Int = 200) async throws -> T {
		var request = URLRequest(url: url)

		prepare(request: &request, method: "GET", headers: headers)
		return try await send(for: request, as: T.self, expects: statusCode)
	}

	private func post<T: Decodable>(_ url: URL, headers: [String: String] = [:], as _: T.Type, expects statusCode: Int = 200) async throws -> T {
		try await post(url, body: [:] as [String: String], headers: headers, as: T.self, expects: statusCode)
	}

	private func post<T: Decodable>(_ url: URL, body: any Encodable, headers: [String: String] = [:], as _: T.Type, expects statusCode: Int = 200) async throws -> T {
		var request = URLRequest(url: url)

		try prepare(request: &request, method: "POST", headers: headers, body: body)
		return try await send(for: request, as: T.self, expects: statusCode)
	}

	private func delete<T: Decodable>(_ url: URL, headers: [String: String] = [:], as _: T.Type, expects statusCode: Int = 200) async throws -> T {
		try await delete(url, body: [:] as [String: String], headers: headers, as: T.self, expects: statusCode)
	}

	private func delete<T: Decodable>(_ url: URL, body: any Encodable, headers: [String: String] = [:], as _: T.Type, expects statusCode: Int = 200) async throws -> T {
		var request = URLRequest(url: url)

		try prepare(request: &request, method: "DELETE", headers: headers, body: body)
		return try await send(for: request, as: T.self, expects: statusCode)
	}

	private func prepare(request: inout URLRequest, method: String = "GET", headers: [String: String] = [:]) {
		request.httpMethod = method

		request.setValue("application/json", forHTTPHeaderField: "Accept")
		if let authToken {
			request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
		}

		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
	}

	private func prepare(request: inout URLRequest, method: String = "POST", headers: [String: String] = [:], body: any Encodable) throws {
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		prepare(request: &request, method: method, headers: headers)
		request.httpBody = try encoder.encode(body)
	}

	private func send<T: Decodable>(for request: URLRequest, as _: T.Type, expects statusCode: Int = 200) async throws -> T {
		var (data, response) = try await URLSession.shared.data(for: request)

		guard let response = response as? HTTPURLResponse else {
			throw Error.requestFailed(response)
		}

		if response.statusCode == statusCode {
			if data.isEmpty { data = "null".data(using: .utf8)! }
			return try decoder.decode(T.self, from: data)
		}

		if response.statusCode == 401 {
			try setAuthToken(nil)
			callbacks.signOut()
			throw Error.authenticationFailed
		}

		throw Error.requestFailed(response)
	}
}

extension API {
	struct Callbacks {
		var onSignIn: [() -> Void] = []
		var onSignOut: [() -> Void] = []

		mutating func onSignIn(_ callback: @escaping () -> Void) {
			onSignIn.append(callback)
		}

		mutating func onSignOut(_ callback: @escaping () -> Void) {
			onSignOut.append(callback)
		}

		func signIn() {
			onSignIn.forEach { $0() }
		}

		func signOut() {
			onSignOut.forEach { $0() }
		}
	}
}
