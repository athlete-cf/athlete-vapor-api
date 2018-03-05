import Foundation
import Fluent
import FluentPostgreSQL
import Vapor

/// A single entry of a Todo list.
final class Todo: PostgreSQLModel {
    
    /// The unique identifier for this `Todo`
    var id: Int?

    /// A title describing what this `Todo` entails
    var title: String
    var note: String?
    
    /// `SoftDeletable.deletedAt`
    var deletedAt: Date?
    
    /// `Timestampable.createdAt`
    var createdAt: Date?
    
    /// `Timestampable.updatedAt`
    var updatedAt: Date?

    /// Creates a new `Todo`
    init(id: Int? = nil, title: String, note: String?) {
        self.id = id
        self.title = title
        self.note = note
    }
}

/// Create/Update timestamps for `Todo`
extension Todo: Timestampable {
    public static var createdAtKey: CreatedAtKey { return \.createdAt }
    
    public static var updatedAtKey: UpdatedAtKey { return \.updatedAt }
}

extension Todo: SoftDeletable {
    static var deletedAtKey: DeletedAtKey { return \.deletedAt }
}

/// Allows `Todo` to be used as a dynamic migration
extension Todo: Migration { }

/// Allows `Todo` to be encoded to and decoded from HTTP messages
extension Todo: Content { }

/// Allows `Todo` to be used as a dynamic parameter in route definitions
extension Todo: Parameter { }

extension Todo {
    struct UpdateRequest: Content {
        let title: String?
        let note: String?
    }
    
    static func oneFromRequest(_ req: Request) throws -> Future<Todo> {
        let id = try req.parameter(Int.self)
        return Todo.query(on: req).filter(\Todo.id == id).first().map(to: Todo.self, { todo in
            guard let todo = todo else {
                throw Abort(.notFound)
            }
            
            return todo
        })
    }
    
    static func replaceFromRequest(_ req: Request) throws -> Future<Todo> {
        let id = try req.parameter(Int.self)
        return try req.content.decode(Todo.self).flatMap(to: Todo.self) { todo in
            todo.id = id
            return todo.update(on: req)
        }
    }
    
    static func updateFromRequest(_ req: Request) throws -> Future<Todo> {
        return try req.content.decode(Todo.UpdateRequest.self).flatMap(to: Todo.self, { update in
            return try Todo.oneFromRequest(req).flatMap(to: Todo.self, { todo in
                if let title = update.title { todo.title = title }
                if let note = update.note { todo.note = note }
                
                return todo.update(on: req)
            })
        })
    }
}

