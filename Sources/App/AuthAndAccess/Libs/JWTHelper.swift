import Foundation
import Vapor
import JWT

class JWTService: Service {
    private let signer: JWTSigner
    
    /// Create a new JWTService for the supplied environment.
    public init() {
        let secret = Environment.JWT_SECRET
        self.signer = JWTSigner.hs256(key: Data(secret.utf8))
    }
    
    func jwtTokenForUser(_ user: User) throws -> String {
        guard let userID = user.id else {
            throw Abort(.badRequest)
        }
        
        let exp = ExpirationClaim(value: Date(timeIntervalSinceNow: (365 * 24 * 60 * 60))) // 365 days
        var jwt = JWT(payload: JWTAuthPayload(exp: exp, userID: userID))
        
        let data = try signer.sign(&jwt)
        
        guard let jwtToken: String = String(data: data, encoding: .utf8) else {
            throw Abort(.badRequest)
        }
        return jwtToken
    }
    
    func parse(_ jwtToken: String) throws -> JWTAuthPayload {
        let jwt = try JWT<JWTAuthPayload>(from: jwtToken, verifiedUsing: signer)
        return jwt.payload
    }
}

struct JWTAuthPayload: JWTPayload {
    
    var exp: ExpirationClaim
    var userID: Int
    
    enum CodingKeys: String, CodingKey {
        case exp
        case userID = "userID"
    }
    
    func verify() throws {
        try exp.verify()
    }
}
