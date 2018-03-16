import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

final class UserProfile: PostgreSQLModel {
    
    /// The unique identifier for this `UserProfile`
    var id: Int?
    
    /// Which `User` belongs this `UserProfile`
    var userID: Int
    
    var fName: String?
    var mName: String?
    var lName: String?
    var nickName: String?
    
    /// `SoftDeletable.deletedAt`
    var deletedAt: Date?
    
    /// `Timestampable.createdAt`
    var createdAt: Date?
    
    /// `Timestampable.updatedAt`
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case fName = "f_name"
        case mName = "m_name"
        case lName = "l_name"
        case nickName = "nick_name"
        case deletedAt = "deleted_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
        var prefixedStringValue: String {
            return "up_" + self.stringValue
        }
    }
    
    /// Creates a new `User`
    init(
        userID: Int, id: Int? = nil,
        fname: String? = nil, mname: String? = nil, lname: String? = nil,
        nickname: String? = nil
        ) {
        self.userID = userID
        self.id = id
        self.fName = fname
        self.mName = mname
        self.lName = lname
        self.nickName = nickname
    }
}

/// Create/Update timestamps for `User`
extension UserProfile: Timestampable {
    public static var createdAtKey: CreatedAtKey { return \.createdAt }
    
    public static var updatedAtKey: UpdatedAtKey { return \.updatedAt }
}

extension UserProfile: SoftDeletable {
    static var deletedAtKey: DeletedAtKey { return \.deletedAt }
}

/// Allows `User` to be used as a dynamic migration
extension UserProfile: Migration {
    /// Migration.prepare
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { schema in
            schema.addField(type: PostgreSQLColumn(type: .int8), name: CodingKeys.id.stringValue, isOptional: false, isIdentifier: true)
            schema.addField(type: PostgreSQLColumn(type: .int8), name: CodingKeys.userID.stringValue, isOptional: false)
            schema.addField(type: PostgreSQLColumn(type: .varchar, size: 140, default: nil), name: CodingKeys.fName.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .varchar, size: 140, default: nil), name: CodingKeys.mName.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .varchar, size: 140, default: nil), name: CodingKeys.lName.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .varchar, size: 140, default: nil), name: CodingKeys.nickName.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.createdAt.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.updatedAt.stringValue, isOptional: true)
            schema.addField(type: PostgreSQLColumn(type: .timestamp), name: CodingKeys.deletedAt.stringValue, isOptional: true)
            schema.addIndex(to: \.userID, isUnique: true)
            schema.addIndex(to: \.fName, isUnique: false)
            schema.addIndex(to: \.mName, isUnique: false)
            schema.addIndex(to: \.lName, isUnique: false)
            schema.addIndex(to: \.nickName, isUnique: false)
        }
    }
    
    /// Migration.revert
    public static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.delete(UserBio.self, on: connection)
    }
}

/// Allows `User` to be encoded to and decoded from HTTP messages
extension UserProfile: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions
extension UserProfile: Parameter { }

extension UserProfile {
    struct UpdateRequest: Content {
        let fName: String?
        let mName: String?
        let lName: String?
        let nickName: String?
    }
    
    static func findOrCreateOnRequest(_ req: Request, by userID: Int) throws -> Future<UserProfile> {
        return User.find(userID, on: req).flatMap(to: UserProfile.self, { user in
            if user == nil { throw Abort(.notFound) }
            
            return UserProfile.query(on: req).filter(\UserProfile.userID == userID).first().flatMap(to: UserProfile.self, { item in
                guard let item = item else {
                    return UserProfile(userID: userID).save(on: req)
                }
                
                return Future(item)
            })
        })
    }
    
    static func createOrUpdateFromRequest(_ req: Request, by userID: Int) throws -> Future<UserProfile> {
        return try req.content.decode(UpdateRequest.self).flatMap(to: UserProfile.self, { update in
            return try UserProfile.findOrCreateOnRequest(req, by: userID).flatMap(to: UserProfile.self, { item in
                item.fName = update.fName
                item.mName = update.mName
                item.lName = update.lName
                item.nickName = update.nickName
                
                return item.save(on: req)
            })
        })
    }
}
