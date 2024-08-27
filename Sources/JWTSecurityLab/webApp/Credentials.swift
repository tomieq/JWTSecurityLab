//
//  Credentials.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 26/08/2024.
//
import Foundation
import Template

class Credentials {
    let data: [User]
    
    init() {
        data = Template.load(relativePath: "passwords.file").output
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.components(separatedBy: CharacterSet(charactersIn: "|")) }
            .map { User(login: $0[0], password: $0[1]) }
        Logger.info("Credentials", "Loaded \(data.count) credentials \(data)")
    }
    
    func user(login: String) -> User? {
        data.first { $0.login == login }
    }
}

struct User {
    let login: String
    let password: String
}
