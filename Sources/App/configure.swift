import Fluent
import FluentPostgreSQL
import Vapor
import Foundation

/// Called before your application initializes.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#configureswift)
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    // Register providers first
    try services.register(FluentPostgreSQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router, env: env)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(AuthMiddleware.self) // Check JWT tokens for all urls expect unsecured
    services.register(middlewares)

    // Configure databases
    var databases = DatabaseConfig()
    
    // Configure a Postgres database
    let host = Environment.DB_HOST
    let port = Environment.DB_PORT
    let user = Environment.DB_USER
    let dbname = Environment.DB_NAME
    let pass = Environment.DB_PASSWORD
    let pgConfig = PostgreSQLDatabaseConfig(hostname: host, port: port, username: user, database: dbname, password: pass)
    let pgDB = PostgreSQLDatabase(config: pgConfig)
    databases.add(database: pgDB, as: .psql)
    
    // Register Auth sevice
    services.register(AuthMiddleware(environment: env))
    
    services.register(JWTService())
    
    // Configure a SQLite database
    //try databases.add(database: SQLiteDatabase(storage: .memory), as: .sqlite)
    
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .psql)
    migrations.add(model: PhoneVerification.self, database: .psql)
    migrations.add(model: User.self, database: .psql)
    services.register(migrations)

    // Configure the rest of your application here
}
