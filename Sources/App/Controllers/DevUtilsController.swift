import Vapor
import Fluent
import FluentPostgreSQL

class DevUtilsController: RouteCollection {
    
    func drop(_ req: Request) throws -> Future<Response> {
        let passCode = try req.parameter(Int.self)
        if passCode != 2384 { throw Abort(.unauthorized) }
        
        let res = Response(using: req)
        let db = DatabaseIdentifier<PostgreSQLDatabase>.psql
        return req.withPooledConnection(to: db) { db -> Future<Response> in
            let sql = "" +
                "DROP SCHEMA public CASCADE;" +
                "CREATE SCHEMA public;" +
                "GRANT ALL ON SCHEMA public TO postgres;" +
                "GRANT ALL ON SCHEMA public TO public;"
            
            return db.simpleQuery(sql).map(to: Response.self, { data in
                print(data)
                
                try res.content.encode(["msg": "All tables dropped"], as: .json)
                
                return res
            })
        }
    }
    
    func banToken(_ req: Request) throws -> Future<JWTBannedToken> {
        let token = try req.parameter(String.self)
        let passCode = try req.parameter(Int.self)
        if passCode != 2384 { throw Abort(.unauthorized) }
        
        let bannedToken = JWTBannedToken(token: token)
        
        return bannedToken.save(on: req)
    }
    
    func boot(router: Router) throws {
        router.get("dropTables", Int.parameter, use: drop)
        router.get("banToken", String.parameter, Int.parameter, use: banToken)
    }
    
}
