import Foundation
import Fluent
import FluentPostgreSQL

extension PostgreSQLData {
    /// Gets a `String` from the supplied path or throws a decoding error.
    public func decodeOrNil<T>(_ type: T.Type) -> T? where T: PostgreSQLDataCustomConvertible {
        do {
            return try T.convertFromPostgreSQLData(self)
        } catch _ { return nil }
    }
}
