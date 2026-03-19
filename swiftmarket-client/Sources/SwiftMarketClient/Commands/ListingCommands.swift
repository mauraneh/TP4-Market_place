import ArgumentParser
import Foundation

struct ListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listings",
        abstract: "List marketplace listings"
    )

    @Option(help: "Page number")
    var page: Int = 1

    @Option(help: "Filter by category")
    var category: String?

    @Option(name: .customLong("query"), help: "Search in listing titles and descriptions")
    var query: String?

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let response = try await api.getListings(
                page: max(page, 1),
                category: category,
                query: query
            )

            guard !response.items.isEmpty else {
                print("No listings found.")
                return
            }

            let isFiltered = (category?.isEmpty == false) || (query?.isEmpty == false)
            if isFiltered {
                let suffix = response.totalCount == 1 ? "result" : "results"
                print("Listings (\(response.totalCount) \(suffix))")
            } else {
                let totalPages = max(response.totalPages, 1)
                print("Listings (page \(response.page)/\(totalPages) - \(response.totalCount) results)")
            }

            printSeparator()
            print("\(padded("ID", width: 36))  \(padded("Title", width: 18))  \(padded("Price", width: 10))  \(padded("Category", width: 12))  Seller")
            for listing in response.items {
                print(
                    "\(padded(listing.id.uuidString, width: 36))  "
                    + "\(padded(listing.title, width: 18))  "
                    + "\(padded(formatPrice(listing.price), width: 10))  "
                    + "\(padded(listing.category, width: 12))  "
                    + "\(listing.seller.username)"
                )
            }

            if !isFiltered && response.page < response.totalPages {
                printSeparator()
                print("Next page: swiftmarket listings --page \(response.page + 1)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct ListingCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listing",
        abstract: "Show the details of a listing"
    )

    @Argument(help: "Listing identifier")
    var id: String

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let listingID = try parseUUID(id, fieldName: "listing ID")
            let listing = try await api.getListing(id: listingID)

            print(listing.title)
            printSeparator(41)
            print("Price:       \(formatPrice(listing.price))")
            print("Category:    \(listing.category)")
            print("Description: \(listing.description)")
            print("Seller:      \(listing.seller.username) (\(listing.seller.email))")
            print("Posted:      \(formatDate(listing.createdAt))")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct PostCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "post",
        abstract: "Create a new listing"
    )

    @Option(help: "Listing title")
    var title: String

    @Option(name: .customLong("desc"), help: "Listing description")
    var desc: String

    @Option(help: "Listing price")
    var price: Double

    @Option(help: "Listing category")
    var category: String

    @Option(help: "Seller identifier")
    var seller: String

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let sellerID = try parseUUID(seller, fieldName: "seller ID")
            let listing = try await api.createListing(
                CreateListingRequest(
                    title: title,
                    description: desc,
                    price: price,
                    category: category,
                    sellerID: sellerID
                )
            )

            print("Listing created successfully.")
            print("ID:          \(listing.id.uuidString)")
            print("Title:       \(listing.title)")
            print("Price:       \(formatPrice(listing.price))")
            print("Category:    \(listing.category)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

struct DeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a listing"
    )

    @Argument(help: "Listing identifier")
    var id: String

    private var api: APIClient { APIClient() }

    func run() async throws {
        do {
            let listingID = try parseUUID(id, fieldName: "listing ID")
            let listing = try await api.getListing(id: listingID)
            try await api.deleteListing(id: listingID)

            print("Listing \"\(listing.title)\" deleted.")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}
