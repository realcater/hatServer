import Fluent
import Vapor

final class ClientSettings: Model, Content {
    static let schema = "serverSettings"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "updatePlayersStatus") var updatePlayersStatus: Double
    @Field(key: "updateGameList") var updateGameList: Double
    @Field(key: "checkOffline") var checkOffline: Double
    @Field(key: "updateFrequent") var updateFrequent: Double
    @Field(key: "updateFullTillNextTry") var updateFullTillNextTry: Double
    
    init() { }
    
    init(id: UUID? = nil, updatePlayersStatus: Double, updateGameList: Double, checkOffline: Double, updateFrequent: Double, updateFullTillNextTry: Double) {
        self.updatePlayersStatus = updatePlayersStatus
        self.updateGameList = updateGameList
        self.checkOffline = checkOffline
        self.updateFrequent = updateFrequent
        self.updateFullTillNextTry = updateFullTillNextTry
    }
    
    
}
extension ClientSettings {
    struct ClientSettingsMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("serverSettings")
                .id()
                .field("updatePlayersStatus", .double, .required)
                .field("updateGameList", .double, .required)
                .field("checkOffline", .double, .required)
                .field("updateFrequent", .double, .required)
                .field("updateFullTillNextTry", .double, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("serverSettings").delete()
        }
    }
}
