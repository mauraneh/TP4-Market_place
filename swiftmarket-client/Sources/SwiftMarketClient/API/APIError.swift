import Foundation

enum APIError: Error {
    case notFound(String)
    case conflict(String)
    case validationFailed(String)
    case serverError(String)
    case connectionFailed
    case decodingError(Error)
}

extension APIError {
    var message: String {
        switch self {
        case .notFound(let message),
             .conflict(let message),
             .validationFailed(let message),
             .serverError(let message):
            return message
        case .connectionFailed:
            return "Could not connect to server at http://localhost:8080.\nMake sure the server is running: swift run in swiftmarket-server/"
        case .decodingError(let error):
            return "Could not decode server response: \(error.localizedDescription)"
        }
    }
}
