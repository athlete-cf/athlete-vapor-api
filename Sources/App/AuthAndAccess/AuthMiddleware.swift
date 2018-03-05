import Foundation
import Async
import Debugging
import HTTP
import Service
import Vapor
import JWT

/// Captures all errors and transforms them into an internal server error.
public final class AuthMiddleware: Middleware, Service {
    
    /// list of unsecured URLs
    /// Order is matter.
    /// Verification stops on first success match.
    /// With [`/v1/auth`, `/v1/auth/code`] last will not be reached
    static var unsecuredPaths = [
        "/v1/auth"
    ]
    
    /// The environment to respect when presenting errors.
    let environment: Environment
    
    /// Create a new AuthMiddleware for the supplied environment.
    public init(environment: Environment) {
        self.environment = environment
    }
    
    /// See `Middleware.respond`
    public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        let promise = Promise<Response>()
        
        try next.respond(to: req).do { res in
            
            for path in AuthMiddleware.unsecuredPaths {
                if !req.http.uri.path.starts(with: path) {
                    print("Secured path")
                    guard let jwtToken = req.http.headers["t"] else {
                        let resp = Response(http: HTTPResponse(status: .unauthorized), using: req)
                        promise.complete(resp)
                        return
                    }
                    
                    do {
                        
                        let jwt = try req.make(JWTService.self)
                        let payload = try jwt.parse(jwtToken)
                        
                        print("Authenticated user ID:", payload.userID)
                        
                        res.http.headers["userID"] = String(payload.userID)
                        promise.complete(res)
                        
                    } catch let e {
                        debugPrint(e)
                        let resp = Response(http: HTTPResponse(status: .unauthorized), using: req)
                        promise.complete(resp)
                        return
                    }
                    
                    break
                } else {
                    print("Unsecured path")
                }
            }
            
            promise.complete(res)
        }.catch { error in
            promise.fail(error)
        }
        
        return promise.future
    }
}

