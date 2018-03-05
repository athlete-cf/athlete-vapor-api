import Foundation
import Vapor
import FluentPostgreSQL
import JWT

// For testing:
// http://httpbin.org/anything
// http://httpbin.org/ip

/// Handle phone number authentication
final class AuthController: RouteCollection {
    
    struct VerifyRequest: Content {
        let phone: String
        let os: String
    }
    
    struct VerifyResponse: Content {
        let requestID: String
    }
    
    struct CheckRequest: Content {
        let requestID: String
        let code: String
    }
    
    struct CheckResponse: Content {
        let token: String
    }
    
    struct GuestRequest: Content {
        let nickname: String
    }
    
    /// Sends SMS with verifycation code to cell phone number and return an verifycation request id
    func checkPhone(_ req: Request) throws -> Future<VerifyResponse> {
        return try req.content.decode(VerifyRequest.self).flatMap(to: VerifyResponse.self) { verifyRes in
            
            return try NexmoService.verify(req: req, phone: verifyRes.phone)
                .flatMap(to: VerifyResponse.self) { res in
                    print("Nexmo verify response", res)
                    
                    if res.status != "0" {
                        print("Nexmo verify response ERROR:", res)
                        switch res.status {
                        case "5": throw Abort(.internalServerError)
                        default: throw Abort(.badRequest)
                        }
                    }
                    
                    let phoneVerification = PhoneVerification(reuestID: res.request_id, phone: verifyRes.phone)
                    return phoneVerification.save(on: req).flatMap(to: VerifyResponse.self, { saved in
                        return Future(VerifyResponse(requestID: res.request_id))
                    })
            }
            
        }
    }
    
    /// Check check verifycation code associated with and verifycation request id
    func checkCode(_ req: Request) throws -> Future<CheckResponse> {
        return try req.content.decode(CheckRequest.self).flatMap(to: CheckResponse.self) { res in
            
            return PhoneVerification.lastFromRequest(req, for: res.requestID)
                .flatMap(to: CheckResponse.self, { phoneVerification in
            
                    return try NexmoService.check(req: req, requestID: res.requestID, code: res.code)
                        .flatMap(to: CheckResponse.self, { nexmoRes in
                            print("Nexmo check response", nexmoRes)
                            
                            guard nexmoRes.request_id != nil else {
                                throw Abort(.internalServerError)
                            }
                            
                            if nexmoRes.status != "0" {
                                print("Nexmo check response ERROR:", nexmoRes)
                                switch nexmoRes.status {
                                case "5": throw Abort(.internalServerError)
                                default: throw Abort(.badRequest)
                                }
                            }

                            return try User.findOrCreateOnRequest(req, by: phoneVerification.phone)
                                .flatMap(to: CheckResponse.self, { user in
                                    let jwt = try req.make(JWTService.self)
                                    let token = try jwt.jwtTokenForUser(user)
                                    return Future(CheckResponse(token: token))
                                })
                    })
            })
        }
    }
    
    /// Guest login
    func guest(_ req: Request) throws -> Future<CheckResponse> {
        return try req.content.decode(GuestRequest.self).flatMap(to: CheckResponse.self) { res in
            return User(nickname: res.nickname).save(on: req)
                .flatMap(to: CheckResponse.self, { user in
                    let jwt = try req.make(JWTService.self)
                    let token = try jwt.jwtTokenForUser(user)
                    return Future(CheckResponse(token: token))
                })
        }
    }
    
    func boot(router: Router) throws {
        let path = "auth".makePathComponent()
        
        router.post(path, "checkphone", use: checkPhone)
        router.post(path, "checkcode", use: checkCode)
        router.post(path, "guest", use: guest)
    }
}
