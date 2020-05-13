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
    var turn: Int
    var explainTime: Date
    var wordsData: [WordData] = []
    var guessedThisTurn: Int
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
    init(id: UUID, name: String, tellGuessed: Int, listenGuessed: Int, accepted: Bool, inGame: Bool) {
        self.id = id
        self.name = name
        self.accepted = accepted
        self.inGame = inGame
        self.tellGuessed = tellGuessed
        self.listenGuessed = listenGuessed
    }
    var id: UUID
    var name: String
    var tellGuessed: Int
    var listenGuessed: Int
    var accepted: Bool
    var inGame: Bool
}

