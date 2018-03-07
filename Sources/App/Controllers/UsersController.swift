import Vapor

class UsersController: RouteCollection {
    
    func index(_ req: Request) throws -> Future<Response> {
        let res = Response(using: req)
        try res.content.encode(["u1", "u2", "u3"], as: .json)
        return Future(res)
    }
    
    /// User profile by user ID
    func profile(_ req: Request) throws -> Future<UserProfile> {
        return try UserProfile.oneFromRequest(req)
    }
    
    func boot(router: Router) throws {
        let path = "users".makePathComponent()
        
        router.get(path, "profile", Int.parameter, use: profile)
    }
    
}
