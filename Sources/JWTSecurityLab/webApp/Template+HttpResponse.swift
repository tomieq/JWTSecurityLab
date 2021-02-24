//
//  Template+HttpResponse.swift
//  
//
//  Created by Tomasz Kucharski on 24/02/2021.
//

import Foundation

extension Template {
    func asResponse(withHeaders headers: [String:String] = [:]) -> HttpResponse {
        if let data = self.output().data(using: .utf8) {
            return .raw(200, "OK", headers, { writer in
                try? writer.write(data)
            })
        }
        return .noContent
    }
}
