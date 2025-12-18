import Foundation

struct Website: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let domain: String?
    let shareId: String?
    let teamId: String?
    let resetAt: Date?
    let createdAt: Date?

    var displayDomain: String {
        domain ?? name
    }
}

struct WebsiteResponse: Codable, Sendable {
    let data: [Website]?
    let count: Int?

    var websites: [Website] {
        data ?? []
    }
}
