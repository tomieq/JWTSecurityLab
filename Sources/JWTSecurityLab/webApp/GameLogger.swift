//
//  GameLogger.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 26/08/2024.
//

enum GameAction {
    case started(game: String)
    case finished(game: String, login: String)
}

class GameLogger {
    static let shared = GameLogger()
    var subscriber: ((GameAction)-> Void)?
    
    private init() {
        
    }
    
    func log(_ action: GameAction) {
        print("GameAction: action: \(action)")
        subscriber?(action)
    }
}
