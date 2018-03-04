import Foundation
import Vapor
import FluentPostgreSQL

/// Handle phone number authentication
final class AuthController: RouteCollection {

    struct PlivoSendRequest: Content {
        static var defaultMediaType = MediaType.json
        
        let src: String
        let dst: String
        let text: String
    }
    
    struct PlivoSendResponse: Content {
        let message: String
        let message_uuid: String
        let api_id: String
    }
    
    /// Sends SMS with verifycation code to cell phone number
    func checkPhone(_ req: Request) throws -> Future<HTTPStatus> {
        
//        let user = "MANWZHNMJIMTM3MWVKYZ"
//        let pasw = "MDZhZGJmMjhhN2U0ZWU5MzUzZjYwMjBjNDk5ODU0"
//        _ = try req.make(Client.self).get("https://\(user):\(pasw)@api.plivo.com/v1/").flatMap(to: String.self, { res in
//            return Future("")
//        })
        
        let plivoSend = PlivoSendRequest(src: "", dst: "", text: "Your code is 934-345")
        
        return try req.make(Client.self)
            .post("https://api.plivo.com/v1/Account/MANWZHNMJIMTM3MWVKYZ/Message/", content: plivoSend)
            .flatMap(to: HTTPStatus.self, { res in
                return try res.content.decode(PlivoSendResponse.self).flatMap(to: HTTPStatus.self) { res in
                    debugPrint(res)
                    return Future(.ok)
                }
        })
        
//        struct IPResponse: Content {
//            let origin: String
//        }
//
//        return try req.make(Client.self).get("http://httpbin.org/ip").flatMap(to: HTTPStatus.self, { res in
//            return try res.content.decode(IPResponse.self).flatMap(to: HTTPStatus.self) { ipResponse in
//                debugPrint(ipResponse)
//                return Future(.ok)
//            }
//        })
    }
    
    func boot(router: Router) throws {
        let path = "auth".makePathComponent()
        
        router.post(path, "sendcode", use: checkPhone)
        router.post(path, "checkcode", use: checkPhone)
    }
}
