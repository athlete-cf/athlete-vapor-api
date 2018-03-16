import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

final class UserBioWithProfile: PostgreSQLModel {
    var id: Int?
    
    /// The unique identifier for this `UserBioWithProfile`
    var user: User
    var bio: UserBio?
    var profile: UserProfile?
    
    /// Creates a new `UserBioWithProfile`
    init(user: User, bio: UserBio?, profile: UserProfile?) {
        self.user = user
        self.bio = bio
        self.profile = profile
    }
}

extension UserBioWithProfile: Content { }

extension UserBioWithProfile {
    static func oneOnRequest(_ req: Request, for userID: Int) throws -> Future<UserBioWithProfile?> {
        let db = DatabaseIdentifier<PostgreSQLDatabase>.psql
        return req.withPooledConnection(to: db) { connection in
            let sql = "" +
            "SELECT " +
                "u.id, u.phone, u.created_at, u.updated_at, " +
                "up.id AS up_id, up.user_id AS up_user_id, up.f_name AS up_f_name, up.m_name AS up_m_name, up.l_name AS up_l_name, up.nick_name AS up_nick_name, up.created_at AS up_created_at, up.updated_at AS up_updated_at, " +
                "ub.id AS ub_id, ub.user_id AS ub_user_id, ub.birthday AS ub_birthday, ub.height AS ub_height, ub.weight AS ub_weight, ub.created_at AS ub_created_at, ub.updated_at AS ub_updated_at " +
            "FROM users AS u " +
            "INNER JOIN userprofiles AS up " +
            "ON up.user_id = u.id " +
            "INNER JOIN userbios AS ub " +
            "ON ub.user_id = u.id " +
            "WHERE u.id = $1 AND u.deleted_at IS NULL; "
            
            return try connection.query(sql, [userID]).map(to: Optional<UserBioWithProfile>.self, { data in
                if let row = data.first {
                    guard let id: Int = try row[User.CodingKeys.id.stringValue]?.decode(Int.self)
                        else { throw Abort(.notFound) }
                    let user = User(id: id, phone: nil)
                    
                    user.phone = row[User.CodingKeys.phone.stringValue]?.decodeOrNil(String.self)
                    user.createdAt = row[User.CodingKeys.createdAt.stringValue]?.decodeOrNil(Date.self)
                    user.updatedAt = row[User.CodingKeys.updatedAt.stringValue]?.decodeOrNil(Date.self)
                    
                    var bio: UserBio?
                    var profile: UserProfile?
                    
                    if
                        let bioID = row[UserBio.CodingKeys.id.prefixedStringValue]?.decodeOrNil(Int.self),
                        let userID = row[UserBio.CodingKeys.userID.prefixedStringValue]?.decodeOrNil(Int.self),
                        let createdAt = row[UserBio.CodingKeys.createdAt.prefixedStringValue]?.decodeOrNil(Date.self),
                        let updatedAt = row[UserBio.CodingKeys.updatedAt.prefixedStringValue]?.decodeOrNil(Date.self)
                    {
                        bio = UserBio(
                            userID: userID,
                            id: bioID,
                            birthday: row[UserBio.CodingKeys.birthday.prefixedStringValue]?.decodeOrNil(Date.self),
                            weight: row[UserBio.CodingKeys.weight.prefixedStringValue]?.decodeOrNil(Float.self),
                            height: row[UserBio.CodingKeys.height.prefixedStringValue]?.decodeOrNil(Float.self)
                        )
                        bio?.createdAt = createdAt
                        bio?.updatedAt = updatedAt
                    }
                    
                    if
                        let profileID = row[UserProfile.CodingKeys.id.prefixedStringValue]?.decodeOrNil(Int.self),
                        let userID = row[UserProfile.CodingKeys.userID.prefixedStringValue]?.decodeOrNil(Int.self),
                        let createdAt = row[UserProfile.CodingKeys.createdAt.prefixedStringValue]?.decodeOrNil(Date.self),
                        let updatedAt = row[UserProfile.CodingKeys.updatedAt.prefixedStringValue]?.decodeOrNil(Date.self)
                    {
                        profile = UserProfile(
                            userID: userID,
                            id: profileID,
                            fname: row[UserProfile.CodingKeys.fName.prefixedStringValue]?.decodeOrNil(String.self),
                            mname: row[UserProfile.CodingKeys.mName.prefixedStringValue]?.decodeOrNil(String.self),
                            lname: row[UserProfile.CodingKeys.lName.prefixedStringValue]?.decodeOrNil(String.self),
                            nickname: row[UserProfile.CodingKeys.nickName.prefixedStringValue]?.decodeOrNil(String.self)
                        )
                        profile?.createdAt = createdAt
                        profile?.updatedAt = updatedAt
                    }
                    
                    return UserBioWithProfile(user: user, bio: bio, profile: profile)
                } else {
                    return nil
                }
            })
        }
    }
}
