//
//  Gamification.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 26/08/2024.
//
import Foundation

class Gamification {
    var games: [Game] = []

    func isGameStarted(_ name: String) -> Bool {
        games.contains{ $0.name == name }
    }
    
    func start(game name: String) {
        terminate(game: name)
        let game = Game(name: name)
        Logger.info("Gamification", "New game \(game.name) started at \(game.started.readable)")
        games.append(game)
        GameLogger.shared.log(.started(game: name))
    }
    
    func terminate(game name: String) {
        games.removeAll { $0.name == name }
    }
    
    func score(game name: String, login: String) {
        guard let game = (games.first { $0.name == name }) else {
            return
        }
        if let _ = (game.users.first { $0.login == login }) {
            return
        }
        let user = GameUser(login: login)
        Logger.info("Gamification", "User \(login) finished game \(game.name) at \(user.finished.readable)")
        game.users.append(user)
        GameLogger.shared.log(.finished(game: name, login: login))
    }
}


class Game {
    let name: String
    let started = Date()
    var users: [GameUser] = []
    
    init(name: String) {
        self.name = name
    }
}

struct GameUser {
    let login: String
    let finished = Date()
}
