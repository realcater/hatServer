import Foundation
import Vapor

struct UpdateData: Codable, Content {
    var gameData: GameData
    var wordsData: [WordData]
}

struct GameSettings: Codable {
    var difficulty: GameDifficulty
    var wordsQty: Int
    var roundDuration: Int
}

struct GameData: Codable, Content {
    var players: [Player]
    var settings: GameSettings
    var gameDifficulty: GameDifficulty
    var leftWords: [String]
    var guessedWords: [String]
    var missedWords: [String]
    var basketWords: [String]
    var basketStatus: [GuessedStatus]
    var time: Int
    var currentWord: String
    var tellerNumber: Int
    var listenerNumber: Int
    var dist: Int
    var started: Bool
    var prevTellerNumber: Int
    var prevListenerNumber: Int
}

struct WordData: Codable, Content {
    var word: String
    var timeGuessed: Double
    var guessedStatus: GuessedStatus
}

enum GuessedStatus: Int, Codable  {
    case guessed
    case left
    case missed
}

enum GameDifficulty: Int, Codable {
    case veryEasy
    case easy
    case normal
    case hard
    case veryHard
    case separator1
    case easyMix
    case normalMix
    case hardMix
}

final class Player: Codable {
    init(id: UUID, name: String, tellGuessed: Int, listenGuessed: Int) {
        self.id = id
        self.name = name
        self.tellGuessed = tellGuessed
        self.listenGuessed = listenGuessed
    }
    var id: UUID
    var name: String
    var tellGuessed: Int
    var listenGuessed: Int
}

