//
//  String+Optional.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 26/08/2024.
//

import Foundation

extension Optional where Wrapped == String {
    var readable: String {
        switch self {
        case .none:
            "nil"
        case .some(let wrapped):
            wrapped
        }
    }
}
