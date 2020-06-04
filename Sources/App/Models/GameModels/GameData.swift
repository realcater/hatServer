import Foundation
import Vapor

final class GameData: Codable, Content {
    var players: [Player]
    var settings: Settings
    var leftWords: [String]
    var guessedWords: [String]
    var missedWords: [String]
    var basketWords: [String]
    var basketStatus: [GuessedStatus]
    var currentWord: String
    var wordsData: [WordData] = []
}


struct Settings: Codable {
    var difficultyRow: Int
    var wordsQtyRow: Int
    var roundDurationRow: Int
}

enum GuessedStatus: Int, Codable  {
    case guessed
    case left
    case missed
}

final class Player: Codable {
    init(id: UUID, name: String, accepted: Bool = false, lastTimeInGame: Date = Date(timeIntervalSince1970: 0)) {
        self.id = id
        self.name = name
        tellGuessed = 0
        listenGuessed = 0
        self.accepted = accepted
        self.lastTimeInGame = lastTimeInGame
    }
    var id: UUID
    var name: String
    var tellGuessed: Int
    var listenGuessed: Int
    var accepted: Bool
    var lastTimeInGame: Date
}

