import Vapor

func validatedContent<T: Content & Validatable>(_ type: T.Type, from req: Request) throws -> T {
    do {
        try type.validate(content: req)
    } catch let error as ValidationsError {
        throw Abort(.unprocessableEntity, reason: String(describing: error))
    }

    return try req.content.decode(T.self)
}
