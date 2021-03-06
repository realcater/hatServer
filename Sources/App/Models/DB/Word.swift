import Fluent
import Vapor

final class Word: Model, Content {
    static let schema = "words"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "word") var word: String
    @Field(key: "timeGuessed") var timeGuessed: Int
    @Field(key: "guessedStatus") var guessedStatus: GuessedStatus
    @Parent(key: "gameID") var game: Game
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?
    
    init() { }

    init(id: UUID? = nil, word: String, timeGuessed: Int, guessedStatus: GuessedStatus, gameID: Game.IDValue)
    {
        self.id = id
        self.word = word
        self.timeGuessed = timeGuessed
        self.guessedStatus = guessedStatus
        self.$game.id = gameID
    }
}
extension Word {
    struct WordMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("words")
                .id()
                .field("word", .string, .required)
                .field("timeGuessed", .double, .required)
                .field("guessedStatus", .int, .required)
                .field("gameID", .uuid, .required, .references("games", "id"))
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .field("deletedAt", .datetime)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("words").delete()
        }
    }
}
