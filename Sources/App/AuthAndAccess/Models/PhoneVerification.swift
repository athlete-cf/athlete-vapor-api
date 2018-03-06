import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class PhoneVerification: PostgreSQLModel {
    
    /// The unique identifier for this `Todo`
    var id: Int?
    
    /// A title describing what this `Todo` entails
    var reuestID: String
    var phone: String
    
    /// `Timestampable.createdAt`
    var createdAt: Date?
    
    /// `Timestampable.updatedAt`
    var updatedAt: Date?
    
    /// Creates a new `Todo`
    init(id: Int? = nil, reuestID: String, phone: String) {
        self.id = id
        self.reuestID = reuestID
        self.phone = phone
    }
}

/// Create/Update timestamps for `Todo`
extension PhoneVerification: Timestampable {
    public static var createdAtKey: CreatedAtKey { return \.createdAt }
    
    public static var updatedAtKey: UpdatedAtKey { return \.updatedAt }
}

/// Allows `Todo` to be used as a dynamic migration
extension PhoneVerification: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages
extension PhoneVerification: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions
extension PhoneVerification: Parameter { }

extension PhoneVerification {
    static func lastFromRequest(_ req: Request, for requestID: String) -> Future<PhoneVerification> {
        
        //let sort = QuerySort(field: "", direction: .ascending)
        return PhoneVerification.query(on: req)
            .filter(\PhoneVerification.reuestID == requestID)
            .sort(\PhoneVerification.createdAt, QuerySortDirection.descending)
            .first()
            .map(to: PhoneVerification.self, { item in
                guard let item = item else {
                    throw Abort(.notFound)
                }
                
                return item
            })
    }
}


