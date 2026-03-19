import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("users")
        users.post(use: create)
        users.get(use: index)
        users.group(":id") { user in
            user.get(use: show)
            user.get("listings", use: listings)
        }
    }

    func create(req: Request) async throws -> Response {
        let payload = try validatedContent(CreateUserRequest.self, from: req)
        let normalizedUsername = payload.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = payload.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let existingUser = try await User.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$username == normalizedUsername)
                group.filter(\.$email == normalizedEmail)
            }
            .first()

        if existingUser != nil {
            throw Abort(.conflict, reason: "A user with this username or email already exists.")
        }
        let user = User(username: normalizedUsername, email: normalizedEmail)

        try await user.save(on: req.db)

        let response = try UserResponse(user: user)
        return try await response.encodeResponse(status: .created, for: req)
    }

    func index(req: Request) async throws -> [UserResponse] {
        let users = try await User.query(on: req.db)
            .sort(\.$username)
            .all()

        return try users.map(UserResponse.init(user:))
    }

    func show(req: Request) async throws -> UserResponse {
        let userID = try req.parameters.require("id", as: UUID.self)
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        return try UserResponse(user: user)
    }

    func listings(req: Request) async throws -> [ListingResponse] {
        let userID = try req.parameters.require("id", as: UUID.self)
        guard let user = try await User.find(userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found.")
        }

        let listings = try await user.$listings.query(on: req.db)
            .with(\.$seller)
            .all()

        return try listings.map(ListingResponse.init(listing:))
    }
}
