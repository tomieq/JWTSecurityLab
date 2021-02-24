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
            
            let filePath = Resource.absolutePath(forPublicResource: request.path)
            if FileManager.default.fileExists(atPath: filePath) {
                do {
                   let file = try filePath.openForReading()
                   let mimeType = filePath.mimeType()
                   var responseHeader: [String: String] = ["Content-Type": mimeType]

                   let attr = try FileManager.default.attributesOfItem(atPath: filePath)
                   if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                       responseHeader["Content-Length"] = String(fileSize)
                   }

                   return .raw(200, "OK", responseHeader, { writer in
                       try writer.write(file)
                       file.close()
                   })
                   
                } catch {
                    Logger.error("Unhandled request", "\(request.method) `\(request.path)`")
                   return .notFound
                }
            }
            Logger.error("Unhandled request", "File `\(filePath)` doesn't exist")
            return .notFound
        }
        
        server.middleware.append { request in
            Logger.info("Incoming request", "\(request.method) \(request.path)")
            return nil
        }
    }
}
