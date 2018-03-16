import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

final class UserBio: PostgreSQLModel {
    
    /// The unique identifier for this `UserBio`
    var id: Int?
    
    /// Which `User` belongs this `UserBio`
    var userID: Int
    
    var birthday: Date?
    var weight: Float?
    var height: Float?
    
    /// `SoftDeletable.deletedAt`
    var deletedAt: Date?
    
    /// `Timestampable.createdAt`
    var createdAt: Date?
    
    /// `Timestampable.updatedAt`
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case birthday
        case weight
        case height
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
        var prefixedStringValue: String {
            return "ub_" + self.stringValue
        }
    }
    
    /// Creates a new `User`
    init(
        userID: Int, id: Int? = nil,
        birthday: Date? = nil,
        weight: Float? = nil, height: Float? = nil
        ) {
        self.userID = userID
        self.id = id
        self.birthday = birthday
        self.weight = weight
        self.height = height
    }
}

/// Create/Update timestamps for `User`
extension UserBio: Timestampable {
    public static var createdAtKey: CreatedAtKey { return \.createdAt }
    
    public static var updatedAtKey: UpdatedAtKey { return \.updatedAt }
}

extension UserBio: SoftDeletable {
    static var deletedAtKey: DeletedAtKey { return \.deletedAt }
}

/// Allows `UserBio` to be used as a dynamic migration
extension UserBio: Migration {
    /// Migration.prepare
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { schema in
            schema.addField(type: PostgreSQLColumn(type: .int8), name: CodingKeys.id.stringValue, isOptional: false, isIdentifier: true)
            schema.addField(type: PostgreSQLColumn(type: .int8), name: CodingKeys.userID.stringValue, isOptional: false)
            schema.addField(type: PostgreSQLColumn(type: .float4), name: CodingKeys.height.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .float4), name: CodingKeys.weight.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.birthday.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.createdAt.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.updatedAt.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.deletedAt.stringValue, isOptional: true)
            schema.addIndex(to: \.userID, isUnique: true)
            schema.addIndex(to: \.height, isUnique: false)
            schema.addIndex(to: \.weight, isUnique: false)
            schema.addIndex(to: \.birthday, isUnique: false)
        }
    }
    
    /// Migration.revert
    public static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.delete(UserBio.self, on: connection)
    }
}

/// Allows `User` to be encoded to and decoded from HTTP messages
extension UserBio: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions
extension UserBio: Parameter { }

extension UserBio {
    struct UpdateRequest: Content {
        let birthday: Date?
        let weight: Float?
        let height: Float?
    }
    
    static func findOrCreateOnRequest(_ req: Request, by userID: Int) throws -> Future<UserBio> {
        return User.find(userID, on: req).flatMap(to: UserBio.self, { user in
            if user == nil { throw Abort(.notFound) }
            
            return UserBio.query(on: req).filter(\UserBio.userID == userID).first().flatMap(to: UserBio.self, { item in
                guard let item = item else {
                    return UserBio(userID: userID).save(on: req)
                }
                
                return Future(item)
            })
        })
    }
    
    static func createOrUpdateFromRequest(_ req: Request, by userID: Int) throws -> Future<UserBio> {
        return try req.content.decode(UpdateRequest.self).flatMap(to: UserBio.self, { update in
            return try UserBio.findOrCreateOnRequest(req, by: userID).flatMap(to: UserBio.self, { item in
                item.birthday = update.birthday
                item.height = update.height
                item.weight = update.weight
                
                return item.save(on: req)
            })
        })
    }
}
