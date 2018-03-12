import Foundation
import Async
import Debugging
import HTTP
import Service
import Vapor
import JWT

/// Captures all errors and transforms them into an internal server error.
public final class AuthMiddleware: Middleware, Service {
    
    enum PathMatchType {
        case starts, equals
    }
    
    /// List of unsecured URLs
    /// Order is matter
    /// Equals match type should be at the begining of the list to prevent unexpected behavior.
    /// Verification stops on first success match
    static var unsecuredPaths: [(String, PathMatchType)] = [
        ("/", .equals),
        ("/v1", .equals),
        ("/v1/", .equals),
        ("/v1/auth", .starts),
        ("/dev/", .starts)
    ]
    
    /// The environment to respect when presenting errors.
    let environment: Environment
    
    /// Create a new AuthMiddleware for the supplied environment.
    public init(environment: Environment) {
        self.environment = environment
    }
    
    /// `Middleware.respond`
    public func respond(to req: Request, chainingTo next: Responder) throws -> Future<Response> {
        let promise = Promise<Response>()
        
        try next.respond(to: req).do { res in
            
            var isUnsecured = false
            
            for (path, matchType) in AuthMiddleware.unsecuredPaths {
                if matchType == .equals && req.http.uri.path == path {
                    isUnsecured = true
                    break
                }
                
                if matchType == .starts && req.http.uri.path.starts(with: path) {
                    isUnsecured = true
                    break
                }
            }
            
            func completeUnauthorized() {
                let resp = Response(http: HTTPResponse(status: .unauthorized), using: req)
                promise.complete(resp)
            }
            
            if !isUnsecured {
                print("Secured path")
                guard let jwtToken = req.http.headers["t"] else {
                    completeUnauthorized()
                    return
                }
                
                JWTBannedToken.find(req, by: jwtToken).addAwaiter(callback: { bannedToken in
                    if let bannedToken = bannedToken.expectation??.token {
                        completeUnauthorized()
                        debugPrint("Banned token:", bannedToken)
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
                        completeUnauthorized()
                        return
                    }
                })
            } else {
                debugPrint("Unsecured path")
                promise.complete(res)
            }
        }.catch { error in
            promise.fail(error)
        }
        
        return promise.future
    }
}

