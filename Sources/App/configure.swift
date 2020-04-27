import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "vapor",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor",
        database: Environment.get("DATABASE_NAME") ?? "vapor"
    ), as: .psql)

    app.migrations.add(User.UserMigration())
    app.migrations.add(Game.GameMigration())
    app.migrations.add(UserGame.UserGameMigration())
    app.migrations.add(LogGameUpdate.LogGameUpdateMigration())
    app.migrations.add(Word.WordMigration())
    
    app.migrations.add(AdminUser())
    app.migrations.add(AppUser())

    // register routes
    try routes(app)
    try jwtSign(app)
    
}
