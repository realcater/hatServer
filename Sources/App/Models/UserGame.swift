import Fluent
import Vapor

final class UserGame: Model, Content {
    static let schema = "users_games"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "userId") var user: User
    @Parent(key: "gameId") var game: Game
    @Field(key: "accepted") var accepted: Bool
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?

    init() { }

    init(id: UUID? = nil, userID: User.IDValue, gameID: Game.IDValue, accepted: Bool) {
        self.id = id
        self.$user.id = userID
        self.$game.id = gameID
        self.accepted = accepted
    }
}

extension UserGame {
    struct UserGameMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("users_games")
                .id()
                .field("userId", .uuid, .required, .references("users", "id"))
                .field("gameId", .uuid, .required, .references("games", "id"))
                .field("accepted", .bool)
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .field("deletedAt", .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("users_games").delete()
        }
    }
}
