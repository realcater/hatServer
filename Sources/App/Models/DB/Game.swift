import Fluent
import Vapor

final class Game: Model, Content {
    static let schema = "games"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "data") var data: Data
    @Field(key: "turn") var turn: Int
    @Field(key: "guessedThisTurn") var guessedThisTurn: Int
    @Field(key: "explainTime") var explainTime: Date
    @Parent(key: "userID") var userOwner: User
    @Siblings(through: UserGame.self, from: \.$game, to: \.$user) var users: [User]
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?
    
    init() { }

    init(id: UUID? = nil, data: Data, userOwnerID: User.IDValue)
    {
        self.id = id
        self.data = data
        self.guessedThisTurn = 0
        self.turn = 0
        self.explainTime = Date().addingTimeInterval(-100000)
        self.$userOwner.id = userOwnerID
    }
    final class Public: Codable, Content {
        var gameID: UUID
        var userOwnerName: String
        var turn: Int
        var createdAt: Date
        
        init(gameID: UUID, userOwnerName: String, turn: Int, createdAt: Date) {
            self.gameID = gameID
            self.userOwnerName = userOwnerName
            self.turn = turn
            self.createdAt = createdAt
        }
    }
    final class UUIDOnly: Codable, Content {
        var gameID: UUID
        init(gameID: UUID) {
            self.gameID = gameID
        }
    }
    func convertToUUIDOnly() -> UUIDOnly {
        return UUIDOnly(gameID: self.id!)
    }
}
extension Game {
    struct GameMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("games")
                .id()
                .field("data", .data, .required)
                .field("turn", .int)
                .field("guessedThisTurn", .int)
                .field("explainTime", .datetime)
                .field("userID", .uuid, .required, .references("users", "id"))
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
