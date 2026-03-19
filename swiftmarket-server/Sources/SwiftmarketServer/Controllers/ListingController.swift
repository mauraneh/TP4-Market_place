import Fluent
import Vapor

struct ListingController: RouteCollection {
    private struct ListingIndexQuery: Content {
        var page: Int?
        var per: Int?
        var category: String?
        var q: String?
    }

    func boot(routes: any RoutesBuilder) throws {
        let listings = routes.grouped("listings")
        listings.get(use: index)
        listings.post(use: create)
        listings.group(":id") { listing in
            listing.get(use: show)
            listing.delete(use: delete)
        }
    }

    func index(req: Request) async throws -> PagedListingResponse {
        let query = try req.query.decode(ListingIndexQuery.self)
        let page = max(query.page ?? 1, 1)
        let per = min(max(query.per ?? 10, 1), 20)

        let totalBuilder = Listing.query(on: req.db)
        applyFilters(from: query, to: totalBuilder)
        let totalCount = try await totalBuilder.count()

        let itemsBuilder = Listing.query(on: req.db)
        applyFilters(from: query, to: itemsBuilder)

        let listings = try await itemsBuilder
            .with(\.$seller)
            .sort(\.$createdAt, .descending)
            .range((page - 1) * per..<(page - 1) * per + per)
            .all()

        let totalPages: Int
        if totalCount == 0 {
            totalPages = 0
        } else {
            totalPages = Int(ceil(Double(totalCount) / Double(per)))
        }

        return try PagedListingResponse(
            items: listings.map(ListingResponse.init(listing:)),
            page: page,
            totalPages: totalPages,
            totalCount: totalCount
        )
    }

    func create(req: Request) async throws -> Response {
        let payload = try validatedContent(CreateListingRequest.self, from: req)

        guard try await User.find(payload.sellerID, on: req.db) != nil else {
            throw Abort(.notFound, reason: "Seller not found.")
        }

        let listing = Listing(
            title: payload.title,
            description: payload.description,
            price: payload.price,
            category: payload.category,
            sellerID: payload.sellerID
        )

        try await listing.save(on: req.db)
        try await listing.$seller.load(on: req.db)

        let response = try ListingResponse(listing: listing)
        return try await response.encodeResponse(status: .created, for: req)
    }

    func show(req: Request) async throws -> ListingResponse {
        let listingID = try req.parameters.require("id", as: UUID.self)
        guard let listing = try await Listing.query(on: req.db)
            .with(\.$seller)
            .filter(\.$id == listingID)
            .first()
        else {
            throw Abort(.notFound, reason: "Listing not found.")
        }

        return try ListingResponse(listing: listing)
    }

    func delete(req: Request) async throws -> HTTPStatus {
        let listingID = try req.parameters.require("id", as: UUID.self)
        guard let listing = try await Listing.find(listingID, on: req.db) else {
            throw Abort(.notFound, reason: "Listing not found.")
        }

        try await listing.delete(on: req.db)
        return .noContent
    }

    private func applyFilters(from query: ListingIndexQuery, to builder: QueryBuilder<Listing>) {
        if let category = query.category?.trimmingCharacters(in: .whitespacesAndNewlines), !category.isEmpty {
            builder.filter(\.$category == category)
        }

        if let search = query.q?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
            builder.group(.or) { group in
                group.filter(\.$title ~~ search)
                group.filter(\.$description ~~ search)
            }
        }
    }
}
