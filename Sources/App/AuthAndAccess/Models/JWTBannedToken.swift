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
extension JWTBannedToken: Migration {
    /// Migration.prepare
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { schema in
            schema.addField(type: PostgreSQLColumn(type: .int8), name: CodingKeys.id.stringValue, isOptional: false, isIdentifier: true)
            schema.addField(type: PostgreSQLColumn(type: .varchar, size: 512, default: nil), name: CodingKeys.token.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.createdAt.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.updatedAt.stringValue, isOptional: true)
            schema.addIndex(to: \.id, isUnique: true)
            schema.addIndex(to: \.token, isUnique: false)
        }
    }
    
    /// Migration.revert
    public static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.delete(JWTBannedToken.self, on: connection)
    }
}

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


