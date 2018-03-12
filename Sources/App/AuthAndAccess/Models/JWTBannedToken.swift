import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class JWTBannedToken: PostgreSQLModel {
    
    /// The unique identifier for this `Todo`
    var id: Int?
    
    /// A title describing what this `Todo` entails
    var token: String
    
    /// `Timestampable.createdAt`
    var createdAt: Date?
    
    /// `Timestampable.updatedAt`
    var updatedAt: Date?
    
    /// Creates a new `Todo`
    init(id: Int? = nil, token: String) {
        self.id = id
        self.token = token
    }
}

/// Create/Update timestamps for `Todo`
extension JWTBannedToken: Timestampable {
    public static var createdAtKey: CreatedAtKey { return \.createdAt }
    
    public static var updatedAtKey: UpdatedAtKey { return \.updatedAt }
}

/// Allows `Todo` to be used as a dynamic migration
extension JWTBannedToken: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages
extension JWTBannedToken: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions
extension JWTBannedToken: Parameter { }

extension JWTBannedToken {
    static func find(_ req: Request, by token: String) -> Future<JWTBannedToken?> {
        return JWTBannedToken.query(on: req)
            .filter(\JWTBannedToken.token == token)
            .first()
            .map(to: Optional<JWTBannedToken>.self, { item in
                return item
            })
    }
}


