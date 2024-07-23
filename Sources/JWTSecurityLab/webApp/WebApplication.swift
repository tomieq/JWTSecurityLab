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


class WebApplication {

    private var mainTemplate: Template {
        let template = Template.load(absolutePath: BootstrapTemplate.absolutePath(for: "templates/index.tpl.html")!)
        template.assign(["url": "css/login-form.css"], inNest: "css")
        return template
    }
    private var bodyTemplate: Template {
        Template.load(relativePath: "templates/pageResponse.html")
    }
    
    init(_ server: HttpServer) {

        server.get["/"] = { [unowned self] request, _ in
            let page = self.bodyTemplate
            page.assign("body", "You are connected. Let's wait for others")
            return .ok(.html(self.mainTemplate.assign("body", page)))
        }
        
        server["/lab1"] = { [unowned self] request, responseHeaders in
            
            let cookieName = "lab1_cookie"
            let secret = "secret".data(using: .utf8)!
            // answer = eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJ1c2VyIjoiYWRtaW4ifQ.
            
            let page = self.bodyTemplate
            page.assign("title", "Lab 1: CVE-2020-15957")
            page.assign(["url":"/css/login-form.css"], inNest: "css")
            
            let loginTemplate = Template.load(relativePath: "templates/loginForm.html")
            let instructions = Template.load(relativePath: "templates/lab1Instructions.html")
            loginTemplate.assign("instructions", instructions)
            
            var authorizedLogin: String?
            
            if let token = request.cookies.get(cookieName) {
                do {
                    authorizedLogin = try JWTdecode(token, algorithm: .hs256(secret)).claims["user"] as? String
                } catch {
                    // simulated bahaviour of CVE-2020-15957
                    do {
                        authorizedLogin = try JWTdecode(token, algorithm: .none).claims["user"] as? String
                    } catch {
                        page.assign(["message":"Failed to decode JWT: \(error)"], inNest: "error")
                    }
                }
            }
            
            if let login = request.formData.get("login"),
               let password = request.formData.get("password") {
                    if ["jim", "admin"].contains(login) {
                        if login == "jim", password == "12345" {
                            let claims = [
                                "clientIP": request.peerName ?? "",
                                "user": login,
                                "path": request.path,
                                "requestID": request.id.uuidString,
                                "validFrom": Date().jwt,
                                "validTo": Date().addingTimeInterval(60 * 60).jwt
                            ]
                            let token = JWTencode(claims: claims, algorithm: .hs256(secret))
                            responseHeaders.setCookie(name: cookieName, value: token)
                            authorizedLogin = login
                        } else {
                            let errorMsg = String(format: "Invalid password for user <b>%@</b>.",  login)
                            page.assign(["message":errorMsg], inNest: "error")
                        }
                    } else {
                        let errorMsg = String(format: "User <b>%@</b> does't exist.", login)
                        page.assign(["message":errorMsg], inNest: "error")
                    }
            } else if let _ = request.formData.get("logout"){
                responseHeaders.unsetCookie(name: cookieName)
                page.assign(["message":"Successfully signed out."], inNest: "success")
                authorizedLogin = nil
            }
            
            if let login = authorizedLogin, ["jim", "admin"].contains(login) {
                loginTemplate.assign(["path":request.path,"login":login], inNest: "authorized")
                if login == "admin" {
                    page.assign(["message":"Job well done! Contratulations. You have taken over admin's account!"], inNest: "success")
                } else {
                    let msg = String(format: "Successfully logged as <b>%@</b>. Now your task is to breach the security and authenticate as admin.", login)
                    page.assign(["message":msg], inNest: "info")
                }
            } else {
                loginTemplate.assign(["path":request.path], inNest: "unauthorized")
            }
            
            page.assign("body", loginTemplate)
            return .ok(.html(self.mainTemplate.assign("body", page)))
        }
        
        server["/lab2"] = { [unowned self] request, responseHeaders in
            
            let cookieName = "lab2_cookie"
            let secret = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9".data(using: .utf8)!
            
            let page = self.bodyTemplate
            page.assign("title", "Lab 2: CVE-2019-7644")
            page.assign(["url":"/css/login-form.css"], inNest: "css")
            
            let loginTemplate = Template.load(relativePath: "templates/loginForm.html")
            let instructions = Template.load(relativePath: "templates/lab2Instructions.html")
            loginTemplate.assign("instructions", instructions)
            
            var authorizedLogin: String?
            
            func html(_ txt: String) -> String {
                "<span class='fw-light'>\(txt)</span>"
            }
            if let token = request.cookies[cookieName] {
                do {
                    authorizedLogin = try JWTdecode(token, algorithm: .hs256(secret)).claims["user"] as? String
                } catch {
                    // simulated bahaviour of CVE-2019-7644
                    let tokenParts = token.split(separator: ".").map{ "\($0)" }
                    if tokenParts.count == 3, let base = "\(tokenParts[0]).\(tokenParts[1])".data(using: .utf8) {
                        let alg = Algorithm.hs256(secret)
                        let signature = base64encode(alg.algorithm.sign(base))
                        let errorMsg = String(format: "Invalid signature. Expected <b>%@</b> got <b>%@</b>",
                                              html(signature),
                                              html(tokenParts[2]))
                        page.assign(["message":errorMsg], inNest: "error")
                    }
                }
            }
            
            if let login = request.formData.get("login"),
               let password = request.formData.get("password") {
                    if ["jim", "admin"].contains(login) {
                        if login == "jim", password == "12345" {
                            let token = JWTencode(claims: ["user": login], algorithm: .hs256(secret))
                            responseHeaders.setCookie(name: cookieName, value: token)
                            authorizedLogin = login
                        } else {
                            let errorMsg = String(format: "Invalid password for user <b>%@</b>.", login)
                            page.assign(["message":errorMsg], inNest: "error")
                        }
                    } else {
                        let errorMsg = String(format: "User <b>%@</b> does't exist.", login)
                        page.assign(["message":errorMsg], inNest: "error")
                    }
            } else if let _ = request.formData.get("logout") {
                responseHeaders.unsetCookie(name: cookieName)
                page.assign(["message":"Successfully signed out."], inNest: "success")
                authorizedLogin = nil
            }
            
            if let login = authorizedLogin, ["jim", "admin"].contains(login) {
                loginTemplate.assign(["login":login], inNest: "authorized")
                if login == "admin" {
                    page.assign(["message":"Job well done! Contratulations. You have taken over admin's account!"], inNest: "success")
                } else {
                    let msg = String(format: "Successfully logged as <b>%@</b>. Now your task is to breach the security and authenticate as admin.", login)
                    page.assign(["message":msg], inNest: "info")
                }
            } else {
                loginTemplate.assign([:], inNest: "unauthorized")
            }
            
            page.assign("body", loginTemplate)
            return .ok(.html(self.mainTemplate.assign("body", page)))
        }
        
        server.notFoundHandler = { request, _ in
            // serve Bootstrap static files
            if let filePath = BootstrapTemplate.absolutePath(for: request.path) {
                try HttpFileResponse.with(absolutePath: filePath)
            }
            try HttpFileResponse.with(absolutePath: Resource().absolutePath(for: request.path))
            return .notFound(.text("Page not found"))
        }
        
        server.middleware.append( { request, header in
            print("Request \(request.id) \(request.method) \(request.path) from \(request.peerName ?? "")")
            request.onFinished = { id, code, duration in
                print("Request \(id) finished with \(code) in \(String(format: "%.3f", duration)) seconds")
            }
            return nil
        })
    }
}
