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
    static func oneOnRequest(_ req: Request, for userID: Int) throws -> Future<UserBioWithProfile> {
        let promise = Promise<UserBioWithProfile>()
        
        let db = DatabaseIdentifier<PostgreSQLDatabase>.psql
        return req.withPooledConnection(to: db) { connection -> Future<UserBioWithProfile> in
            var profileFull = UserBioWithProfile(user: User(id: 0, phone: nil), bio: nil, profile: nil)
            
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
            "WHERE u.id = 1 AND u.deleted_at IS NULL; "
            
            return try connection.query(sql, [userID]).map(to: UserBioWithProfile.self, { data in
                //print(data)
                
                for row in data {
                    guard let id: Int = try row[User.CodingKeys.id.stringValue]?.decode(Int.self)
                    else { throw Abort(.notFound) }
                    let user = User(id: id, phone: nil)
                    
                    user.phone = (try? row[User.CodingKeys.phone.stringValue]?.decode(String.self)) ?? nil
                    user.createdAt = (try? row[User.CodingKeys.createdAt.stringValue]?.decode(Date.self)) ?? nil
                    user.updatedAt = (try? row[User.CodingKeys.updatedAt.stringValue]?.decode(Date.self)) ?? nil
                    
                    var bio: UserBio?
                    var profile: UserProfile?
                    
                    if
                        let bioID = (try? row[UserBio.CodingKeys.id.prefixedStringValue]?.decode(Int.self)) ?? nil,
                        let userID = (try? row[UserBio.CodingKeys.userID.prefixedStringValue]?.decode(Int.self)) ?? nil,
                        let createdAt = (try? row[UserBio.CodingKeys.createdAt.prefixedStringValue]?.decode(Date.self)) ?? nil,
                        let updatedAt = (try? row[UserBio.CodingKeys.updatedAt.prefixedStringValue]?.decode(Date.self)) ?? nil
                    {
                        bio = UserBio(
                            userID: userID,
                            id: bioID,
                            birthday: (try? row[UserBio.CodingKeys.birthday.prefixedStringValue]?.decode(Date.self)) ?? nil,
                            weight: (try? row[UserBio.CodingKeys.weight.prefixedStringValue]?.decode(Float.self)) ?? nil,
                            height: (try? row[UserBio.CodingKeys.height.prefixedStringValue]?.decode(Float.self)) ?? nil
                        )
                        bio?.createdAt = createdAt
                        bio?.updatedAt = updatedAt
                    }
                    
                    if
                        let profileID = (try? row[UserProfile.CodingKeys.id.prefixedStringValue]?.decode(Int.self)) ?? nil,
                        let userID = (try? row[UserProfile.CodingKeys.userID.prefixedStringValue]?.decode(Int.self)) ?? nil,
                        let createdAt = (try? row[UserProfile.CodingKeys.createdAt.prefixedStringValue]?.decode(Date.self)) ?? nil,
                        let updatedAt = (try? row[UserProfile.CodingKeys.updatedAt.prefixedStringValue]?.decode(Date.self)) ?? nil
                    {
                        profile = UserProfile(
                            userID: userID,
                            id: profileID,
                            fname: (try? row[UserProfile.CodingKeys.fName.prefixedStringValue]?.decode(String.self)) ?? nil,
                            mname: (try? row[UserProfile.CodingKeys.mName.prefixedStringValue]?.decode(String.self)) ?? nil,
                            lname: (try? row[UserProfile.CodingKeys.lName.prefixedStringValue]?.decode(String.self)) ?? nil,
                            nickname: (try? row[UserProfile.CodingKeys.nickName.prefixedStringValue]?.decode(String.self)) ?? nil
                        )
                        profile?.createdAt = createdAt
                        profile?.updatedAt = updatedAt
                    }
                    
                    profileFull = UserBioWithProfile(user: user, bio: bio, profile: profile)
                }
                
                return profileFull
            })
        }
        
//        try User.oneFromRequest(req, by: userID).addAwaiter(callback: { result in
//            guard let user = result.expectation else {
//                promise.fail(Abort(.notFound))
//                return
//            }
//
//            profileFull = UserBioWithProfile(user: user, bio: nil, profile: nil)
//
//            var counter = 0
//
//            UserBio.query(on: req)
//                .filter(\UserBio.userID == userID)
//                .first().addAwaiter(callback: { resultBio in
//                    profileFull.bio = resultBio.expectation ?? nil
//
//                    counter += 1
//                    if counter == 2 { promise.complete(profileFull) }
//                })
//
//            UserProfile.query(on: req)
//                .filter(\UserProfile.userID == userID)
//                .first().addAwaiter(callback: { resultProfile in
//                    profileFull.profile = resultProfile.expectation ?? nil
//
//                    counter += 1
//                    if counter == 2 { promise.complete(profileFull) }
//                })
//        })
        
        //req.withPooledConnection(to: ., closure: <#T##(DatabaseConnection) throws -> Future<T>#>)
        
        return promise.future
    }
}
