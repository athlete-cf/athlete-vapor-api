import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

final class User: PostgreSQLModel {
    
    /// The unique identifier for this `User`
    var id: Int?
    
    var phone: String?
    
    var nickname: String?
    
    /// `SoftDeletable.deletedAt`
    var deletedAt: Date?
    
    /// `Timestampable.createdAt`
    var createdAt: Date?
    
    /// `Timestampable.updatedAt`
    var updatedAt: Date?
    
    /// Creates a new `User`
    init(id: Int? = nil, phone: String? = nil, nickname: String? = nil) {
        self.id = id
        self.phone = phone
        self.nickname = nickname
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
extension User: Migration { }

/// Allows `User` to be encoded to and decoded from HTTP messages
extension User: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions
extension User: Parameter { }

extension User {
    struct UpdateRequest: Content {
        let fname: String?
        let sname: String?
    }
    
    static func findOrCreateOnRequest(_ req: Request, by phone: String) throws -> Future<User> {
        return User.query(on: req).filter(\User.phone == phone).first().flatMap(to: User.self, { item in
            guard let item = item else {
                return User(phone: phone).save(on: req)
            }
            
            return Future(item)
        })
    }
    
    static func oneFromRequest(_ req: Request) throws -> Future<User> {
        let id = try req.parameter(Int.self)
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
    
    static func updateFromRequest(_ req: Request) throws -> Future<User> {
        return try req.content.decode(Todo.UpdateRequest.self).flatMap(to: User.self, { update in
            return try User.oneFromRequest(req).flatMap(to: User.self, { item in
//                if let item = update.title { item.title = title }
//                if let note = update.note { item.note = note }
                
                return item.update(on: req)
            })
        })
    }
}
