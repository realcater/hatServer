import Fluent
import Vapor
import JWT

final class User: Model, Content, ModelAuthenticatable {
    var exp: ExpirationClaim = .init(value: Date().addingTimeInterval(JWTConfig.expirationTime))

    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
    
    static let schema = "users"
    static let usernameKey = \User.$name
    static let passwordHashKey = \User.$passwordHash
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "passwordHash") var passwordHash: String
    @Siblings(through: UserGame.self, from: \.$user, to: \.$game) var games: [Game]
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "updatedAt", on: .update) var updatedAt: Date?
    @Timestamp(key: "deletedAt", on: .delete) var deletedAt: Date?
    
    init() { }

    init(id: UUID? = nil, name: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.passwordHash = passwordHash
    }
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    struct UserMigration: Migration {
        func prepare(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("users")
                .id()
                .field("name", .string, .required)
                .field("passwordHash", .string, .required)
                .field("createdAt", .datetime)
                .field("updatedAt", .datetime)
                .field("deletedAt", .datetime)
                .unique(on: "name")
                .create()
        }

        func revert(on database: Database) -> EventLoopFuture<Void> {
            return database.schema("users").delete()
        }
    }
}
