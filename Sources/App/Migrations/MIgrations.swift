import Fluent
import Vapor

struct AdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        guard let adminPassword = Environment.get("ADMIN_PASSWORD") else {
            fatalError("There is no ADMIN_PASSWORD")
        }
        do {
            let adminUser = User(name: "admin", passwordHash: try Bcrypt.hash(adminPassword))
            return adminUser.save(on: database)
        } catch {
            fatalError("Error hash-making")
        }
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No revert"))
    }
}

struct AppUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        guard let appPassword = Environment.get("APP_PASSWORD") else {
            fatalError("There is no APP_PASSWORD")
        }
        do {
            let appUser = User(name: "app", passwordHash: try Bcrypt.hash(appPassword))
            return appUser.save(on: database)
        } catch {
            fatalError("Error hash-making")
        }
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No revert"))
    }
}

struct ClientSettingsInit: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let settings = ClientSettings(updatePlayersStatus: 5.0, updateGameList: 5.0, checkOffline: 10.0, updateFrequent: 1.0, updateFullTillNextTry: 1.0, minimumAppVersion: 2, logGameUpdate: true)
        return settings.save(on: database)
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeFailedFuture(Abort(.badRequest, reason: "No revert"))
    }
}
