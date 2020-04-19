import Fluent
import Vapor

final class Token: Model, Content, ModelTokenAuthenticatable {    
    typealias User = App.User
    static let schema = "tokens"
    static let valueKey = \Token.$value
    static let userKey = \Token.$user
    
    var isValid: Bool {
        return self.expiresAt > Date() && !self.isRevoked
    }
    
    @ID(key: .id) var id: UUID?
    @Field(key: "tokenValue") var value: String
    @Parent(key: "userId") var user: User
    @Field(key: "expiresAt") var expiresAt: Date
    @Field(key: "isRevoked") var isRevoked: Bool

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.$user.id = userID
        // Set expirty to 30 days
        self.expiresAt = Date().advanced(by: 60 * 60 * 24 * 30)
        self.isRevoked = false
    }
}

struct CreateToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tokens")
            .id()
            .field("tokenValue", .string, .required)
            .field("userId", .uuid, .required, .references("users", "id"))
            .field("expiresAt", .date, .required)
            .field("isRevoked", .bool, .required)
            .unique(on: "tokenValue")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("tokens").delete()
    }
}

