import ArgumentParser
import Foundation

struct CreateUserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-user",
        abstract: "Create a new user"
    )

    @Option(help: "Username for the new account")
    var username: String

    @Option(help: "Email for the new account")
    var email: String

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let user = try await api.createUser(CreateUserRequest(username: username, email: email))
            print("User created successfully.")
            print("ID:       \(user.id.uuidString)")
            print("Username: \(user.username)")
            print("Email:    \(user.email)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UsersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "users",
        abstract: "List all users"
    )

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let users = try await api.getUsers()
            print("Users (\(users.count))")

            guard !users.isEmpty else {
                return
            }

            printSeparator()
            print("\(padded("ID", width: 36))  \(padded("Username", width: 10))  Email")
            for user in users {
                print("\(padded(user.id.uuidString, width: 36))  \(padded(user.username, width: 10))  \(user.email)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user",
        abstract: "Show a user profile"
    )

    @Argument(help: "User identifier")
    var id: String

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let userID = try parseUUID(id, fieldName: "user ID")
            let user = try await api.getUser(id: userID)

            print(user.username)
            print("Email:        \(user.email)")
            print("Member since: \(formatDate(user.createdAt))")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct UserListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user-listings",
        abstract: "List listings for a specific user"
    )

    @Argument(help: "User identifier")
    var userID: String

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let parsedUserID = try parseUUID(userID, fieldName: "user ID")
            let user = try await api.getUser(id: parsedUserID)
            let listings = try await api.getUserListings(userID: parsedUserID)

            print("Listings by \(user.username) (\(listings.count))")

            guard !listings.isEmpty else {
                return
            }

            printSeparator()
            print("\(padded("ID", width: 36))  \(padded("Title", width: 18))  \(padded("Price", width: 10))  Category")
            for listing in listings {
                print("\(padded(listing.id.uuidString, width: 36))  \(padded(listing.title, width: 18))  \(padded(formatPrice(listing.price), width: 10))  \(listing.category)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}
