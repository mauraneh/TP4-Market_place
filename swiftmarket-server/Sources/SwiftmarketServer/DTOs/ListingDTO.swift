import Vapor

struct CreateListingRequest: Content, Validatable {
    var title: String
    var description: String
    var price: Double
    var category: String
    var sellerID: UUID

    static func validations(_ validations: inout Validations) {
        validations.add("title", as: String.self, is: !.empty)
        validations.add("price", as: Double.self, is: .range(0.01...))
        validations.add("category", as: String.self, is: .in(ListingCategory.allCases.map(\.rawValue)))
    }
}

struct ListingResponse: Content {
    var id: UUID
    var title: String
    var description: String
    var price: Double
    var category: String
    var seller: UserResponse
    var createdAt: Date?

    init(listing: Listing) throws {
        guard let id = listing.id else {
            throw Abort(.internalServerError, reason: "Missing listing identifier.")
        }

        guard let seller = listing.$seller.value else {
            throw Abort(.internalServerError, reason: "Listing seller relation was not loaded.")
        }

        self.id = id
        self.title = listing.title
        self.description = listing.description
        self.price = listing.price
        self.category = listing.category
        self.seller = try UserResponse(user: seller)
        self.createdAt = listing.createdAt
    }
}

struct PagedListingResponse: Content {
    var items: [ListingResponse]
    var page: Int
    var totalPages: Int
    var totalCount: Int
}
