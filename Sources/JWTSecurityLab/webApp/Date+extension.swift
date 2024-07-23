//
//  Date+extension.swift
//
//
//  Created by Tomasz Kucharski on 23/07/2024.
//

import Foundation

extension Date {
    var jwt: String {
        let formater = DateFormatter()
        formater.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formater.timeZone = TimeZone(identifier: "UTC")
        formater.calendar = Calendar(identifier: .iso8601)
        formater.locale = Locale(identifier: "en_US_POSIX")
        return formater.string(from: self)
    }
}
