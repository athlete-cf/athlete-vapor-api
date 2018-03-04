import FluentPostgreSQL
import Vapor

extension Model where Self.Database : QuerySupporting {
    public static func allFromRequest(_ req: Request) throws -> Future<[Self]> {
        return Self.query(on: req).all()
    }
}
