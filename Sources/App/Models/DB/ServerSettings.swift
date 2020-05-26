import Fluent
import Vapor

final class ClientSettings: Model, Content {
    static let schema = "serverSettings"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "updatePlayersStatus") var updatePlayersStatus: Int
    @Field(key: "updateGameList") var updateGameList: Int
    @Field(key: "checkOffline") var checkOffline: Int
    @Field(key: "updateFrequent") var updateFrequent: Int
    @Field(key: "updateFullTillNextTry") var updateFullTillNextTry: Int
    
}
extension ClientSettings {
    struct ServerSettingsMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("serverSettings")
                .id()
                .field("updatePlayersStatus", .int, .required)
                .field("updateGameList", .int, .required)
                .field("checkOffline", .int, .required)
                .field("updateFrequent", .int, .required)
                .field("updateFullTillNextTry", .int, .required)
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("serverSettings").delete()
        }
    }
}
