import Fluent
import Vapor

final class ClientSettings: Model, Content {
    static let schema = "clientSettings"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "updatePlayersStatus") var updatePlayersStatus: Double
    @Field(key: "updateGameList") var updateGameList: Double
    @Field(key: "checkOffline") var checkOffline: Double
    @Field(key: "updateFrequent") var updateFrequent: Double
    @Field(key: "updateFullTillNextTry") var updateFullTillNextTry: Double
    @Field(key: "minimumAppVersion") var minimumAppVersion: Int
    
    init() { }
    
    init(id: UUID? = nil, updatePlayersStatus: Double, updateGameList: Double, checkOffline: Double, updateFrequent: Double, updateFullTillNextTry: Double, minimumAppVersion: Int) {
        self.updatePlayersStatus = updatePlayersStatus
        self.updateGameList = updateGameList
        self.checkOffline = checkOffline
        self.updateFrequent = updateFrequent
        self.updateFullTillNextTry = updateFullTillNextTry
        self.minimumAppVersion = minimumAppVersion
    }
    
    
}
extension ClientSettings {
    struct ClientSettingsMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("clientSettings")
                .id()
                .field("updatePlayersStatus", .double, .required)
                .field("updateGameList", .double, .required)
                .field("checkOffline", .double, .required)
                .field("updateFrequent", .double, .required)
                .field("updateFullTillNextTry", .double, .required)
                .field("minimumAppVersion", .int, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("clientSettings").delete()
        }
    }
}
