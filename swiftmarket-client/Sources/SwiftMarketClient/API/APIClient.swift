import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct APIClient {
    let baseURL: String = "http://localhost:8080"

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func createUser(_ body: CreateUserRequest) async throws -> UserResponse {
        try await post("/users", body: body)
    }

    func getUsers() async throws -> [UserResponse] {
        try await get("/users")
    }

    func getUser(id: UUID) async throws -> UserResponse {
        try await get("/users/\(id.uuidString)")
    }

    func getUserListings(userID: UUID) async throws -> [ListingResponse] {
        try await get("/users/\(userID.uuidString)/listings")
    }

    func createListing(_ body: CreateListingRequest) async throws -> ListingResponse {
        try await post("/listings", body: body)
    }

    func getListings(page: Int, category: String?, query: String?) async throws -> PagedListingResponse {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }

        return try await get("/listings", queryItems: queryItems)
    }

    func getListing(id: UUID) async throws -> ListingResponse {
        try await get("/listings/\(id.uuidString)")
    }

    func deleteListing(id: UUID) async throws {
        try await delete(path: "/listings/\(id.uuidString)")
    }

    private func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let url = try makeURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let data = try await perform(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let url = try makeURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let data = try await perform(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func delete(path: String) async throws {
        let url = try makeURL(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        _ = try await perform(request)
    }

    private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.serverError("Invalid server URL.")
        }

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.serverError("Invalid server URL.")
        }

        return url
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.serverError("Invalid server response.")
            }

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw mapError(statusCode: httpResponse.statusCode, data: data)
            }

            return data
        } catch let error as APIError {
            throw error
        } catch is URLError {
            throw APIError.connectionFailed
        } catch {
            throw APIError.serverError(error.localizedDescription)
        }
    }

    private func mapError(statusCode: Int, data: Data) -> APIError {
        let serverError = try? decoder.decode(ServerError.self, from: data)
        let reason = serverError?.reason?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedReason = reason.flatMap { $0.isEmpty ? nil : $0 }

        if let cleanedReason, isDuplicateUserConflict(cleanedReason) {
            return .conflict("A user with this username or email already exists.")
        }

        switch statusCode {
        case 404:
            return .notFound(cleanedReason ?? "Resource not found.")
        case 409:
            return .conflict(cleanedReason ?? "A conflicting resource already exists.")
        case 422:
            if let cleanedReason {
                return .validationFailed("Validation failed.\n\(cleanedReason)")
            }
            return .validationFailed("Validation failed.")
        default:
            return .serverError(cleanedReason ?? "An unexpected server error occurred.")
        }
    }

    private func isDuplicateUserConflict(_ reason: String) -> Bool {
        let lowered = reason.lowercased()
        return lowered.contains("unique constraint failed: users")
            || lowered.contains("users.username")
            || lowered.contains("users.email")
    }
}
