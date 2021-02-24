//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 23/12/2020.
//

import Foundation

let resourcesPath = "/Users/tomieq/bareMetalSwift/fsmMock/Resources/"
//let resourcesPath = FileManager.default.currentDirectoryPath + String.pathSeparator + "Resources" + String.pathSeparator

class WebApplication {

    
    init(_ server: HttpServer) {

        server["/"] = { request in
            return .notFound
        }
        
        server.notFoundHandler = { request in
            Logger.error("Unhandled request", "\(request.method) `\(request.path)`")
            return .notFound
        }
        
        server.middleware.append { request in
            Logger.info("Incoming request", "\(request.method) \(request.path)")
            return nil
        }
    }
}
