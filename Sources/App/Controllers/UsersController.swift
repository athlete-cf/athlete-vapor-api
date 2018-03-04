import Vapor

class UsersController: RouteCollection {
    
    func index(_ req: Request) throws -> Future<Response> {
        let res = Response(using: req)
        try res.content.encode(["u1", "u2", "u3"], as: .json)
        return Future(res)
    }
    
    func boot(router: Router) throws {
        router.get("users", use: index)
    }
    
}
