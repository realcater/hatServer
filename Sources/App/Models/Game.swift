import Fluent
import Vapor

final class Game: Model, Content {
    static let schema = "games"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "data") var data: Data
    @Parent(key: "userId") var userOwner: User
    @Siblings(through: UserGame.self, from: \.$game, to: \.$user) var users: [User]
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?
    
    init() { }

    init(id: UUID? = nil, data: Data, userOwnerID: User.IDValue)//, usersID: [User.IDValue])
    {
        self.id = id
        self.data = data
        self.$userOwner.id = userOwnerID
        
    }
}
extension Game {
    struct GameMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("games")
                .id()
                .field("data", .data, .required)
                .field("userId", .uuid, .required, .references("users", "id"))
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .field("deletedAt", .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("games").delete()
        }
    }
}
