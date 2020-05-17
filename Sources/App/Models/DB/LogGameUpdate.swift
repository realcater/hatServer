import Fluent
import Vapor

final class LogGameUpdate: Model, Content {
    static let schema = "logGameUpdate"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "game") var game: Data
    @Parent(key: "userID") var user: User
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?
    
    init() { }

    init(id: UUID? = nil, game: Data, userID: User.IDValue)
    {
        self.id = id
        self.game = game
        self.$user.id = userID
    }
}
extension LogGameUpdate {
    struct LogGameUpdateMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("logGameUpdate")
                .id()
                .field("game", .data, .required)
                .field("userID", .uuid, .required, .references("users", "id"))
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
