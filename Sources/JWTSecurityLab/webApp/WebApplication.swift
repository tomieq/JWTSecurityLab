//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 23/12/2020.
//

import Foundation


class WebApplication {

    private let rawPage = Resource.getAppResource(relativePath: "templates/pageResponse.html")
    
    init(_ server: HttpServer) {

        server.GET["/"] = { request in
            
            let template = Template(raw: self.rawPage)
            return template.asResponse()
        }
        
        server["/lab1"] = { request in
            
            let cookieName = "lab1_cookie"
            let secret = "secret".data(using: .utf8)!
            // answer = eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJ1c2VyIjoiYWRtaW4ifQ.
            
            let page = Template(raw: self.rawPage)
            page.set(variables: ["title":"Lab 1: CVE-2020-15957"])
            page.set(variables: ["url":"/css/login-form.css"], inNest: "css")
            
            let loginTemplate = Template(from: "templates/loginForm.html")
            let instructions = Template(from: "templates/lab1Instructions.html")
            loginTemplate.set(variables: ["instructions":instructions.output()])
            
            let headers = HttpHeaders()
            var authorizedLogin: String?
            
            if let token = request.cookies[cookieName] {
                do {
                    authorizedLogin = try JWTdecode(token, algorithm: .hs256(secret)).claims["user"] as? String
                } catch {
                    // simulated bahaviour of CVE-2020-15957
                    do {
                        authorizedLogin = try JWTdecode(token, algorithm: .none).claims["user"] as? String
                    } catch {
                        page.set(variables: ["message":"Failed to decode JWT: \(error)"], inNest: "error")
                    }
                }
            }
            
            let formData = request.parseUrlencodedForm()
            if let login = (formData.first { $0.0 == "login" }.map { $0.1 }),
                let password = (formData.first { $0.0 == "password" }.map { $0.1 }) {
                    if ["jim", "admin"].contains(login) {
                        if login == "jim", password == "12345" {
                            let token = JWTencode(claims: ["user": login], algorithm: .hs256(secret))
                            headers.setCookie(name: cookieName, value: token)
                            authorizedLogin = login
                        } else {
                            let errorMsg = String(format: "Invalid password for user %@.", Template.htmlNode(type: "b", content: login))
                            page.set(variables: ["message":errorMsg], inNest: "error")
                        }
                    } else {
                        let errorMsg = String(format: "User %@ does't exist.", Template.htmlNode(type: "b", content: login))
                        page.set(variables: ["message":errorMsg], inNest: "error")
                    }
            } else if let _ = (formData.first { $0.0 == "logout" }.map { $0.1 }) {
                headers.unsetCookie(name: cookieName)
                page.set(variables: ["message":"Successfully signed out."], inNest: "success")
                authorizedLogin = nil
            }
            
            if let login = authorizedLogin, ["jim", "admin"].contains(login) {
                loginTemplate.set(variables: ["path":request.path,"login":login], inNest: "authorized")
                if login == "admin" {
                    page.set(variables: ["message":"Job well done! Contratulations. You have taken over admin's account!"], inNest: "success")
                } else {
                    let msg = String(format: "Successfully logged as %@. Now your task is to breach the security and authenticate as admin.", Template.htmlNode(type: "b", content: login))
                    page.set(variables: ["message":msg], inNest: "info")
                }
            } else {
                loginTemplate.set(variables: ["path":request.path], inNest: "unauthorized")
            }
            
            page.set(variables: ["body": loginTemplate.output()])
            return page.asResponse(withHeaders: headers)
        }
        
        server["/lab2"] = { request in
            
            let cookieName = "lab2_cookie"
            let secret = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9".data(using: .utf8)!
            
            let page = Template(raw: self.rawPage)
            page.set(variables: ["title":"Lab 2: CVE-2019-7644"])
            page.set(variables: ["url":"/css/login-form.css"], inNest: "css")
            
            let loginTemplate = Template(from: "templates/loginForm.html")
            let instructions = Template(from: "templates/lab2Instructions.html")
            loginTemplate.set(variables: ["instructions":instructions.output()])
            
            let headers = HttpHeaders()
            var authorizedLogin: String?
            
            if let token = request.cookies[cookieName] {
                do {
                    authorizedLogin = try JWTdecode(token, algorithm: .hs256(secret)).claims["user"] as? String
                } catch {
                    // simulated bahaviour of CVE-2019-7644
                    let tokenParts = token.split(".")
                    if tokenParts.count == 3, let base = "\(tokenParts[0]).\(tokenParts[1])".data(using: .utf8) {
                        let alg = Algorithm.hs256(secret)
                        let signature = base64encode(alg.algorithm.sign(base))
                        let errorMsg = String(format: "Invalid signature. Expected %@ got %@",
                                              Template.htmlNode(type: "span", attributes: ["class":"fw-light"], content: signature),
                                              Template.htmlNode(type: "span", attributes: ["class":"fw-light"], content: tokenParts[2]))
                        page.set(variables: ["message":errorMsg], inNest: "error")
                    }
                }
            }
            
            let formData = request.parseUrlencodedForm()
            if let login = (formData.first { $0.0 == "login" }.map { $0.1 }),
                let password = (formData.first { $0.0 == "password" }.map { $0.1 }) {
                    if ["jim", "admin"].contains(login) {
                        if login == "jim", password == "12345" {
                            let token = JWTencode(claims: ["user": login], algorithm: .hs256(secret))
                            headers.setCookie(name: cookieName, value: token)
                            authorizedLogin = login
                        } else {
                            let errorMsg = String(format: "Invalid password for user %@.", Template.htmlNode(type: "b", content: login))
                            page.set(variables: ["message":errorMsg], inNest: "error")
                        }
                    } else {
                        let errorMsg = String(format: "User %@ does't exist.", Template.htmlNode(type: "b", content: login))
                        page.set(variables: ["message":errorMsg], inNest: "error")
                    }
            } else if let _ = (formData.first { $0.0 == "logout" }.map { $0.1 }) {
                headers.unsetCookie(name: cookieName)
                page.set(variables: ["message":"Successfully signed out."], inNest: "success")
                authorizedLogin = nil
            }
            
            if let login = authorizedLogin, ["jim", "admin"].contains(login) {
                loginTemplate.set(variables: ["login":login], inNest: "authorized")
                if login == "admin" {
                    page.set(variables: ["message":"Job well done! Contratulations. You have taken over admin's account!"], inNest: "success")
                } else {
                    let msg = String(format: "Successfully logged as %@. Now your task is to breach the security and authenticate as admin.", Template.htmlNode(type: "b", content: login))
                    page.set(variables: ["message":msg], inNest: "info")
                }
            } else {
                loginTemplate.set(variables: nil, inNest: "unauthorized")
            }
            
            page.set(variables: ["body": loginTemplate.output()])
            return page.asResponse(withHeaders: headers)
        }
        
        server.notFoundHandler = { request in
            
            let filePath = Resource.absolutePath(forPublicResource: request.path)
            if FileManager.default.fileExists(atPath: filePath) {

                guard let file = try? filePath.openForReading() else {
                    Logger.error("File", "Could not open `\(filePath)`")
                    return .notFound
                }
                let mimeType = filePath.mimeType()
                let responseHeaders = HttpHeaders().addHeader("Content-Type", mimeType)

                if let attr = try? FileManager.default.attributesOfItem(atPath: filePath),
                    let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    responseHeaders.addHeader("Content-Length", String(fileSize))
                }

                return .raw(200, "OK", responseHeaders, { writer in
                    try writer.write(file)
                    file.close()
                })
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
