//
//  WebApplication.swift
//  
//
//  Created by Tomasz Kucharski on 23/12/2020.
//

import Foundation


class WebApplication {

    
    init(_ server: HttpServer) {

        server.GET["/"] = { request in
            
            let template = Template(raw: Resource.getAppResource(relativePath: "templates/pageResponse.html"))
            return template.asResponse()
        }
        
        server["/lab1"] = { request in
            
            let cookieName = "lab1_cookie"
            // answer = eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJ1c2VyIjoiYWRtaW4ifQ.
            
            let page = Template(raw: Resource.getAppResource(relativePath: "templates/pageResponse.html"))
            page.set(variables: ["title":"Lab 1: CVE-2020-15957"])
            page.set(variables: ["url":"/css/login-form.css"], inNest: "css")
            
            let loginTemplate = Template(raw: Resource.getAppResource(relativePath: "templates/loginForm.html"))
            let instructions = Template(raw: Resource.getAppResource(relativePath: "templates/lab1Instructions.html"))
            loginTemplate.set(variables: ["instructions":instructions.output()])
            
            let headers = HttpHeaders()
            var authorizedLogin: String?
            
            if let token = request.cookies[cookieName] {
                do {
                    authorizedLogin = try JWTdecode(token, algorithm: .hs256("secret".data(using: .utf8)!)).claims["user"] as? String
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
                            let token = JWTencode(claims: ["user": login], algorithm: .hs256("secret".data(using: .utf8)!))
                            headers.setCookie(name: cookieName, value: token + ";Max-Age=3000; HttpOnly, Secure")
                            authorizedLogin = login
                        } else {
                            page.set(variables: ["message":"Invalid password for user <b>\(login)</b>."], inNest: "error")
                        }
                    } else {
                        page.set(variables: ["message":"User <b>\(login)</b> does't exist."], inNest: "error")
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
                    page.set(variables: ["message":"Successfully logged as \(login). Now your task is to breach the security and authenticate as admin."], inNest: "info")
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
                do {
                   let file = try filePath.openForReading()
                   let mimeType = filePath.mimeType()
                    let responseHeaders = HttpHeaders().addHeader("Content-Type", mimeType)

                   let attr = try FileManager.default.attributesOfItem(atPath: filePath)
                   if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    responseHeaders.addHeader("Content-Length", String(fileSize))
                   }

                   return .raw(200, "OK", responseHeaders, { writer in
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
