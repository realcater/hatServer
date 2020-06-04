import Fluent
import Vapor

final class Game: Model, Content {
    static let schema = "games"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "code") var code: String?
    @Field(key: "data") var data: Data
    @Field(key: "turn") var turn: Int
    @Field(key: "guessedThisTurn") var guessedThisTurn: Int
    @Field(key: "lastWord") var lastWord: String?
    @Field(key: "explainTime") var explainTime: Date
    @Field(key: "basketChange") var basketChange: Int
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
        self.turn = -1
        self.basketChange = 0
        self.explainTime = Date().addingTimeInterval(-100000)
        self.$userOwner.id = userOwnerID
        self.code = GameCode.new()
        print("GameCode.codes=\(GameCode.codes)")
    }
    
    final class ListElement: Codable, Content {
        var id: UUID
        var userOwnerName: String
        var turn: Int
        var createdAt: Date
        
        init(id: UUID, userOwnerName: String, turn: Int, createdAt: Date) {
            self.id = id
            self.userOwnerName = userOwnerName
            self.turn = turn
            self.createdAt = createdAt
        }
    }
    func convertToListElement() -> ListElement {
        return ListElement(id: id!, userOwnerName: userOwner.name, turn: turn, createdAt: createdAt!)
    }
    
    final class Created: Codable, Content {
        var id: UUID
        var code: String?
        
        init(id: UUID, code: String?) {
            self.id = id
            self.code = code
        }
    }
    func convertToCreated() -> Created {
        return Created(id: self.id!, code: self.code)
    }
    
    final class Frequent: Codable, Content {
        internal init(turn: Int, guessedThisTurn: Int, lastWord: String?, explainTime: Date, basketChange: Int) {
            self.turn = turn
            self.guessedThisTurn = guessedThisTurn
            self.lastWord = lastWord
            self.explainTime = explainTime
            self.basketChange = basketChange
        }
        
        var turn: Int
        var guessedThisTurn: Int
        var lastWord: String?
        var explainTime: Date
        var basketChange: Int
    }
    func convertToFrequent() -> Frequent {
        return Frequent(turn: turn, guessedThisTurn: guessedThisTurn, lastWord: lastWord, explainTime: explainTime, basketChange: basketChange)
    }
    
    
    final class Full: Codable, Content {
        internal init(id: UUID, code: String?, data: GameData, userOwnerID: UUID, turn: Int, guessedThisTurn: Int, lastWord: String?, explainTime: Date, basketChange: Int) {
            self.id = id
            self.code = code
            self.data = data
            self.userOwnerID = userOwnerID
            self.turn = turn
            self.guessedThisTurn = guessedThisTurn
            self.lastWord = lastWord
            self.explainTime = explainTime
            self.basketChange = basketChange
        }
        
        var id: UUID
        var code: String?
        var data: GameData
        var userOwnerID: UUID
        var turn: Int
        var guessedThisTurn: Int
        var lastWord: String?
        var explainTime: Date
        var basketChange: Int
    }
    func convertToFull() -> Full {
        let gameData = try! JSONDecoder().decode(GameData.self, from: data)
        return Full(id: id!, code: code, data: gameData, userOwnerID: $userOwner.id, turn: turn, guessedThisTurn: guessedThisTurn, lastWord: lastWord, explainTime: explainTime, basketChange: basketChange)
    }
}
extension Game {
    struct GameMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("games")
                .id()
                .field("data", .data, .required)
                .field("turn", .int, .required)
                .field("guessedThisTurn", .int, .required)
                .field("explainTime", .datetime, .required)
                .field("basketChange", .int, .required)
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
    struct GameMigration20200602: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("games")
                .field("code", .string)
                .field("lastWord", .string)
                .update()
        }
        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("games")
                .deleteField("code")
                .deleteField("lastWord")
                .update()
        }
    }
}
