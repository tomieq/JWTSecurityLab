//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 23/12/2020.
//

import Foundation
import Swifter
import Template
import BootstrapTemplate

enum SecError: Error {
    case missingClaim(String)
}

class WebApplication {
    let credentials = Credentials()
    let sessionManager = SessionManager()
    let gamification = Gamification()
    let server: HttpServer

    var mainTemplate: BootstrapTemplate {
        let template = BootstrapTemplate()
        template.addCSS(url: "css/login-form.css")
        return template
    }
    var bodyTemplate: Template {
        Template.cached(relativePath: "templates/body.html")
    }
    func claims(_ request: HttpRequest) -> ClaimSet {
        var claims = ClaimSet()
        claims.notBefore = Date()
        claims.expiration = Date().addingTimeInterval(60 * 60)
        claims["path"] = request.path
        claims["requestID"] = request.id.uuidString
        claims["now"] = Date().jwt
        return claims
    }
    
    init(_ server: HttpServer) {

        self.server = server
    
        server.get["/"] = { [unowned self] request, _ in
            let pageBody = self.bodyTemplate
            pageBody["content"] = "You are connected. Let's wait for others"
            let response = mainTemplate
            response.body = pageBody
            return .ok(.html(response))
        }

        setupLab1()
        setupLab2()
        setupPanel()
        
        server.notFoundHandler = { request, _ in
            // serve Bootstrap static files
            if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
                try HttpFileResponse.with(absolutePath: filePath)
            }
            try HttpFileResponse.with(absolutePath: Resource().absolutePath(for: request.path))
            return .notFound(.text("Page not found at \(request.path)"))
        }
        
        server.middleware.append( { request, header in
            Logger.info("WebApplication", "Request \(request.id) \(request.method) \(request.path) from \(request.peerName ?? "")")
            request.onFinished = { id, code, duration in
                Logger.info("WebApplication", "Request \(id) finished with \(code) in \(String(format: "%.3f", duration)) seconds")
            }
            return nil
        })
    }
}
