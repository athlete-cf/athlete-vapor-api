import Foundation
import Vapor

extension Environment {
    static let JWT_SECRET = Environment.get("JWT_SECRET")!
    static let NEXMO_KEY = Environment.get("NEXMO_KEY")!
    static let NEXMO_SECRET = Environment.get("NEXMO_SECRET")!
}
