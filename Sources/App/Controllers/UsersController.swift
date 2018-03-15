import Vapor
import Fluent
import FluentPostgreSQL

class UsersController: RouteCollection {
    
    func index(_ req: Request) throws -> Future<Response> {
        let res = Response(using: req)
        try res.content.encode(["u1", "u2", "u3"], as: .json)
        return Future(res)
    }
    
    /// User profile by user ID
    func profile(_ req: Request) throws -> Future<UserProfile> {
        let userID = try req.parameter(Int.self)
        return try UserProfile.findOrCreateOnRequest(req, by: userID)
    }
    
    /// User bio by user ID
    func bio(_ req: Request) throws -> Future<UserBio> {
        let userID = try req.parameter(Int.self)
        return try UserBio.findOrCreateOnRequest(req, by: userID)
    }
    
    /// Create or update user Bio
    func updateOrCreateBio(_ req: Request) throws -> Future<UserBio> {
        let userID = try req.parameter(Int.self)
        return try UserBio.createOrUpdateFromRequest(req, by: userID)
    }
    
    /// Create or update user Profile
    func updateOrCreateProfile(_ req: Request) throws -> Future<UserProfile> {
        let userID = try req.parameter(Int.self)
        return try UserProfile.createOrUpdateFromRequest(req, by: userID)
    }
    
    /// User Profile with Bio
    func bioWithProfile(_ req: Request) throws -> Future<UserBioWithProfile> {
        let userID = try req.parameter(Int.self)
        return try UserBioWithProfile.oneOnRequest(req, for: userID)
    }
    
    func boot(router: Router) throws {
        let path = "users".makePathComponent()
        
        // Profile
        router.get(path, Int.parameter, "profile", use: profile)
        router.post(path, Int.parameter, "profile", use: updateOrCreateProfile)
        
        // Bio
        router.get(path, Int.parameter, "bio", use: bio)
        router.post(path, Int.parameter, "bio", use: updateOrCreateBio)
        
        // User with bio and profile
        router.get(path, Int.parameter, "bio-with-profile", use: bioWithProfile)
    }
    
}
