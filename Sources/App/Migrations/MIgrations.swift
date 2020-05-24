import Fluent
import Vapor

struct AdminUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        guard let adminPassword = Environment.get("ADMIN_PASSWORD") else {
            print("There is no ADMIN_PASSWORD")
            return Abort(.badRequest, reason: "There is no ADMIN_PASSWORD") as! EventLoopFuture<Void>
        }
        do {
            let adminUser = User(name: "admin", passwordHash: try Bcrypt.hash(adminPassword))
            return adminUser.save(on: database)
        } catch {
            print("Error hash-making")
            return Abort(.badRequest, reason: "Error hash-making") as! EventLoopFuture<Void>
        }
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Abort(.badRequest, reason: "No revert") as! EventLoopFuture<Void>
    }
}

struct AppUser: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        guard let adminPassword = Environment.get("APP_PASSWORD") else {
            print("There is no APP_PASSWORD")
            return Abort(.badRequest, reason: "There is no APP_PASSWORD") as! EventLoopFuture<Void>
        }
        do {
            let adminUser = User(name: "app", passwordHash: try Bcrypt.hash(adminPassword))
            return adminUser.save(on: database)
        } catch {
            print("Error hash-making")
            return Abort(.badRequest, reason: "Error hash-making") as! EventLoopFuture<Void>
        }
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Abort(.badRequest, reason: "No revert") as! EventLoopFuture<Void>
    }
}

struct ClientSettingsInit: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let settings = ClientSettings(updatePlayersStatus: 5.0, updateGameList: 5.0, checkOffline: 10.0, updateFrequent: 1.0, updateFullTillNextTry: 1.0)
        return settings.save(on: database)
    }
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return Abort(.badRequest, reason: "No revert") as! EventLoopFuture<Void>
    }
}
