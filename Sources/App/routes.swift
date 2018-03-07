import Routing
import Foundation
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router, env: Environment) throws {

    // Example of creating a Service and using it.
    router.get("hash", String.parameter) { req -> String in
        // Create a BCryptHasher using the Request's Container
        let hasher = try req.make(BCryptHasher.self)

        // Fetch the String parameter (as described in the route)
        let string = try req.parameter(String.self)

        // Return the hashed string!
        return try hasher.make(string)
    }
    
    struct AppInfoResponse: Content {
        static let defaultMediaType: MediaType = .json
        
        let name: String
        let versions: [String]
        let environment: String
    }
    
    let appInfo = AppInfoResponse (
        name: "Athlete API",
        versions: ["v1"],
        environment: env.name
    )
    
    router.get("/") { _ in appInfo }
    
    let dev = router.grouped("dev")
    try dev.register(collection: DevUtilsController())
    
    let v1 = router.grouped("v1")
    try v1.register(collection: TodoController())
    try v1.register(collection: UsersController())
    try v1.register(collection: AuthController())
    v1.get("/") { _ in appInfo }
}
