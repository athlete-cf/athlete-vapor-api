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
        case userID
        case fName
        case mName
        case lName
        case nickName
        case deletedAt
        case createdAt
        case updatedAt
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
        }
    }
    
    public static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return Database.delete(User.self, on: connection)
    }
}

/// Allows `User` to be encoded to and decoded from HTTP messages
extension UserProfile: Content { }

/// Allows `User` to be used as a dynamic parameter in route definitions
extension UserProfile: Parameter { }

extension UserProfile {
    struct UpdateRequest: Content {
        let fname: String?
        let mname: String?
        let lname: String?
        let nickname: String?
    }
    
    static func findOrCreateOnRequest(_ req: Request, by userID: Int) throws -> Future<UserProfile> {
        return UserProfile.query(on: req).filter(\UserProfile.userID == userID).first().flatMap(to: UserProfile.self, { item in
            guard let item = item else {
                return UserProfile(userID: userID).save(on: req)
            }
            
            return Future(item)
        })
    }
    
    static func oneFromRequest(_ req: Request) throws -> Future<UserProfile> {
        let id = try req.parameter(Int.self)
        return UserProfile.query(on: req).filter(\UserProfile.id == id).first().map(to: UserProfile.self, { item in
            guard let item = item else {
                throw Abort(.notFound)
            }
            
            return item
        })
    }
    
    static func replaceFromRequest(_ req: Request) throws -> Future<UserProfile> {
        let id = try req.parameter(Int.self)
        return try req.content.decode(UserProfile.self).flatMap(to: UserProfile.self) { todo in
            todo.id = id
            return todo.update(on: req)
        }
    }
    
    static func updateFromRequest(_ req: Request) throws -> Future<UserProfile> {
        return try req.content.decode(UpdateRequest.self).flatMap(to: UserProfile.self, { update in
            return try UserProfile.oneFromRequest(req).flatMap(to: UserProfile.self, { item in
                if let fname = update.fname { item.fName = fname }
                if let mname = update.mname { item.mName = mname }
                if let lname = update.lname { item.lName = lname }
                if let nickname = update.nickname { item.nickName = nickname }
                
                return item.update(on: req)
            })
        })
    }
}
