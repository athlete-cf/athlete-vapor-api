import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

final class User: PostgreSQLModel {
    
    enum Role: String {
        case user = "user"
        case coach = "coach"
    }
    
    /// The unique identifier for this `User`
    var id: Int?
    
    /// The unique phone for this `User`
    var phone: String?
    
    /// `SoftDeletable.deletedAt`
    var deletedAt: Date?
    
    /// `Timestampable.createdAt`
    var createdAt: Date?
    
    /// `Timestampable.updatedAt`
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case phone
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Creates a new `User`
    init(id: Int? = nil, phone: String? = nil) {
        self.id = id
        self.phone = phone
    }
}

/// Create/Update timestamps for `User`
extension User: Timestampable {
    public static var createdAtKey: CreatedAtKey { return \.createdAt }
    
    public static var updatedAtKey: UpdatedAtKey { return \.updatedAt }
}

extension User: SoftDeletable {
    static var deletedAtKey: DeletedAtKey { return \.deletedAt }
}

/// Allows `User` to be used as a dynamic migration
extension User: Migration {
    /// Migration.prepare
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { schema in
            schema.addField(type: PostgreSQLColumn(type: .int8), name: CodingKeys.id.stringValue, isOptional: false, isIdentifier: true)
            schema.addField(type: PostgreSQLColumn(type: .varchar, size: 80, default: nil), name: CodingKeys.phone.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.createdAt.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.updatedAt.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.deletedAt.stringValue, isOptional: true)
            schema.addIndex(to: \.phone, isUnique: true)
        }
    }
    
    /// Migration.revert
    public static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.delete(User.self, on: connection)
    }
}

/// Allows `User` to be encoded to and decoded from HTTP messages
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions
extension User: Parameter { }

extension User {
    struct UpdateRequest: Content {
        let phone: String?
    }
    
    static func findOrCreateOnRequest(_ req: Request, by phone: String) throws -> Future<User> {
        return User.query(on: req).filter(\User.phone == phone).first().flatMap(to: User.self, { item in
            guard let item = item else {
                return User(phone: phone).save(on: req)
            }
            
            return Future(item)
        })
    }
    
    static func oneFromRequest(_ req: Request, by id: Int) throws -> Future<User> {
        return User.query(on: req).filter(\User.id == id).first().map(to: User.self, { item in
            guard let item = item else {
                throw Abort(.notFound)
            }
            
            return item
        })
    }
    
    static func replaceFromRequest(_ req: Request) throws -> Future<User> {
        let id = try req.parameter(Int.self)
        return try req.content.decode(User.self).flatMap(to: User.self) { todo in
            todo.id = id
            return todo.update(on: req)
        }
    }
    
    static func updateFromRequest(_ req: Request, by id: Int) throws -> Future<User> {
        return try req.content.decode(UpdateRequest.self).flatMap(to: User.self, { update in
            return try User.oneFromRequest(req, by: id).flatMap(to: User.self, { item in
                if let phone = update.phone { item.phone = phone }
                
                return item.update(on: req)
            })
        })
    }
}
