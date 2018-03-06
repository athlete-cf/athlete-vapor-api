import Foundation
import Vapor

struct NexmoVerifyRequest: Content {
    let api_key: String
    let api_secret: String
    let number: String
    let brand: String
}

struct NexmoVerifyResponse: Content {
    let request_id: String
    let status: String
}

struct NexmoCheckRequest: Content {
    let api_key: String
    let api_secret: String
    let request_id: String
    let code: String
}

struct NexmoCheckResponse: Content {
    let request_id: String?
    let status: String
    let error_text: String?
    let event_id: String?
    let price: String?
    let currency: String?
}

class NexmoService: Service {
    static func verify(req: Request, phone: String) throws -> Future<NexmoVerifyResponse> {
        let verifyRequest = NexmoVerifyRequest(
            api_key: Environment.NEXMO_KEY,
            api_secret: Environment.NEXMO_SECRET,
            number: phone,
            brand: "Athlete CF"
        )
        
        // TODO: for debug
        return Future(
            NexmoVerifyResponse(request_id: phone, status: "0")
        )
        
        return try req.make(Client.self)
            .post("https://api.nexmo.com/verify/json", content: verifyRequest)
            .flatMap(to: NexmoVerifyResponse.self, { res in
                return try res.content.decode(NexmoVerifyResponse.self)
            })
    }
    
    static func check(req: Request, requestID: String, code: String) throws -> Future<NexmoCheckResponse> {
        let checkRequest = NexmoCheckRequest(
            api_key: Environment.NEXMO_KEY,
            api_secret: Environment.NEXMO_SECRET,
            request_id: requestID, code: code
        )
        
        // TODO: for debug
        return Future(
            NexmoCheckResponse(
                request_id: requestID, status: "0",
                error_text: nil, event_id: "sdfew3fdsf",
                price: "0.1000", currency: "EUR"
            )
        )
        
        return try req.make(Client.self)
            .post("https://api.nexmo.com/verify/json", content: checkRequest)
            .flatMap(to: NexmoCheckResponse.self, { res in
                return try res.content.decode(NexmoCheckResponse.self)
            })
    }
}
