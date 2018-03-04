import Vapor
import FluentPostgreSQL

/// Controlers basic CRUD operations on `Todo`s.
final class TodoController: RouteCollection {
    
    /// Returns a list of all `Todo`s.
    func all(_ req: Request) throws -> Future<[Todo]> {
        return try Todo.allFromRequest(req)
    }
    
    /// Returns a list of all `Todo`s.
    func one(_ req: Request) throws -> Future<Todo> {
        return try Todo.oneFromRequest(req)
    }

    /// Saves a decoded `Todo` to the database.
    func create(_ req: Request) throws -> Future<Todo> {
        return try req.content.decode(Todo.self).flatMap(to: Todo.self) { todo in
            return todo.save(on: req)
        }
    }
    
    /// Replace a decoded `Todo` in the database
    func put(_ req: Request) throws -> Future<Todo> {
        return try Todo.replaceFromRequest(req)
    }
    
    /// Modify a decoded `Todo` in the database
    func patch(_ req: Request) throws -> Future<Todo> {
        return try Todo.updateFromRequest(req)
    }

    /// Deletes a parameterized `Todo`.
    func delete(_ req: Request) throws -> Future<Todo> {
        return try req.parameter(Todo.self).flatMap(to: Todo.self) { todo in
            return todo.delete(on: req)
        }
        //.transform(to: .ok)
    }
    
    func boot(router: Router) throws {
        let path = "todos".makePathComponent()
        
        router.get(path, use: all)
        router.post(path, use: create)
        router.get(path, Int.parameter, use: one)
        router.put(path, Int.parameter, use: put)
        router.patch(path, Int.parameter, use: patch)
        router.delete(path, Todo.parameter, use: delete)
    }
}
