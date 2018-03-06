import Foundation
import Vapor

extension Environment {
    static let DB_HOST = Environment.get("DB_HOST") ?? "localhost"
    static let DB_PORT = UInt16(Environment.get("DB_PORT") ?? "n/a") ?? 5432
    static let DB_USER = Environment.get("DB_USER") ?? "postgres"
    static let DB_NAME = Environment.get("DB_NAME") ?? "postgres"
    static let DB_PASSWORD = Environment.get("DB_PASSWORD")
}
