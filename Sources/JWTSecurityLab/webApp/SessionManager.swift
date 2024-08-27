//
//  SessionManager.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 26/08/2024.
//

import Foundation

class SessionManager {
    private let queue = DispatchQueue(label: "SessionManager", attributes: .concurrent)
    var sessions: [Session] = []
    
    func startFor(login: String) -> Session {
        queue.sync(flags: .barrier) {
            sessions.removeAll { $0.login == login }
            let session = Session(login: login)
            sessions.append(session)
            return session
        }
    }
    
    func loginFor(sessionID: String?) -> String? {
        guard let sessionID else { return nil }
        return queue.sync {
            sessions.first { $0.id == sessionID }?.login
        }
    }
}

struct Session {
    let id: String
    let login: String
    
    init(login: String) {
        self.id = UUID().uuidString
        self.login = login
    }
}
