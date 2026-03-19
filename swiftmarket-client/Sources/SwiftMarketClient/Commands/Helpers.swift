import Foundation

enum CLIError: LocalizedError {
    case invalidUUID(String)

    var errorDescription: String? {
        switch self {
        case .invalidUUID(let field):
            return "Invalid \(field)."
        }
    }
}

func handleAPIError(_ error: Error) {
    if let apiErr = error as? APIError {
        printError(apiErr.message)
    } else {
        printError(error.localizedDescription)
    }
}

func printError(_ message: String) {
    fputs("Error: \(message)\n", stderr)
}

func parseUUID(_ value: String, fieldName: String) throws -> UUID {
    guard let uuid = UUID(uuidString: value) else {
        throw CLIError.invalidUUID(fieldName)
    }
    return uuid
}

func formatPrice(_ value: Double) -> String {
    String(format: "%.2f€", value)
}

func formatDate(_ date: Date?) -> String {
    guard let date else {
        return "Unknown"
    }
    return cliDateFormatter.string(from: date)
}

func printSeparator(_ width: Int = 65) {
    print(String(repeating: "-", count: width))
}

func padded(_ value: String, width: Int) -> String {
    let output = truncated(value, width: width)
    return output + String(repeating: " ", count: max(0, width - output.count))
}

func truncated(_ value: String, width: Int) -> String {
    guard value.count > width else {
        return value
    }

    guard width > 3 else {
        return String(value.prefix(width))
    }

    return String(value.prefix(width - 3)) + "..."
}

private let cliDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
