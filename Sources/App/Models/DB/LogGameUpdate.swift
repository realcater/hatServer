import Fluent
import Vapor

final class LogGameUpdate: Model, Content {
    static let schema = "logGameUpdate"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "data") var data: Data
    @Parent(key: "userID") var userOwner: User
    @Parent(key: "gameID") var game: Game
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?
    
    init() { }

    init(id: UUID? = nil, data: Data, userOwnerID: User.IDValue, gameID: Game.IDValue)
    {
        self.id = id
        self.data = data
        self.$userOwner.id = userOwnerID
        self.$game.id = gameID
        
    }
}
extension LogGameUpdate {
    struct LogGameUpdateMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("logGameUpdate")
                .id()
                .field("data", .data, .required)
                .field("userID", .uuid, .required, .references("users", "id"))
                .field("gameID", .uuid, .required, .references("games", "id"))
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .field("deletedAt", .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("logGameUpdate").delete()
        }
    }
}
