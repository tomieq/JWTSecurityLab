//
//  WebApplication+lab2.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 27/08/2024.
//
import Template

extension WebApplication {
    func setupLab2() {
        server["/lab2"] = { [unowned self] request, responseHeaders in
            
            let cookieName = "lab2_cookie"
            let secret = "secret".data(using: .utf8)!
            let sessionKey = "fd3"
            // answer = eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.payload.
            
            let response = mainTemplate
            let pageBody = self.bodyTemplate
            response.title = "Lab 2"
            
            guard gamification.isGameStarted("lab2") else {
                pageBody["content"] = "Lab2 did not start yet"
                response.body = pageBody
                return .ok(.html(response))
            }
            
            let loginTemplate = Template.cached(relativePath: "templates/loginForm.html")
            let instructions = Template.cached(relativePath: "templates/lab2Instructions.html")
            if request.queryParams.get("tip") == "show" {
                instructions.assign(TemplateVariables(), inNest: "tip")
            }
            loginTemplate["instructions"] = instructions
            
            var authorizedLogin: String?
            var realLogin: String?
            
            if let token = request.cookies.get(cookieName) {
                do {
                    let jwt = try JWTdecode(token, algorithm: .hs256(secret))
                    guard let sessionID = jwt.claims[sessionKey] as? String,
                          let previousLogin = sessionManager.loginFor(sessionID: sessionID)else {
                        throw SecError.missingClaim(sessionKey)
                    }
                    authorizedLogin = jwt.claims["user"] as? String
                    realLogin = previousLogin
                } catch {
                    // simulated bahaviour of CVE-2020-15957
                    do {
                        let jwt = try JWTdecode(token, algorithm: .none)
                        guard let sessionID = jwt.claims[sessionKey] as? String,
                              let previousLogin = sessionManager.loginFor(sessionID: sessionID)else {
                            throw SecError.missingClaim(sessionKey)
                        }
                        authorizedLogin = jwt.claims["user"] as? String
                        realLogin = previousLogin
                    } catch {
                        pageBody.assign(["message":"Failed to decode JWT: \(error)"], inNest: "error")
                    }
                }
            }
            
            if let login = request.formData.get("login"),
               let password = request.formData.get("password") {
                if let user = credentials.user(login: login) {
                    if password == user.password {
                        let session = sessionManager.startFor(login: login)
                        var claims = self.claims(request)
                        claims["user"] = login
                        claims[sessionKey] = session.id
                        let token = JWTencode(claims: claims, algorithm: .hs256(secret))
                        responseHeaders.setCookie(name: cookieName, value: token)
                        authorizedLogin = login
                        
                    } else {
                        let errorMsg = String(format: "Invalid password for user <b>%@</b>.",  login)
                        pageBody.assign(["message":errorMsg], inNest: "error")
                    }
                } else {
                    let errorMsg = String(format: "User <b>%@</b> does't exist.", login)
                    pageBody.assign(["message":errorMsg], inNest: "error")
                }
            } else if let _ = request.formData.get("logout"){
                responseHeaders.unsetCookie(name: cookieName)
                pageBody.assign(["message":"Successfully signed out."], inNest: "success")
                authorizedLogin = nil
            }
            
            if let login = authorizedLogin {
                loginTemplate.assign(["path":request.path,"login":login], inNest: "authorized")
                if login == "admin" {
                    pageBody.assign(["message":"Job well done \(realLogin.readable)! Contratulations. You have taken over admin's account!"], inNest: "success")
                    response.addJS(url: "confetti.browser.min.js")
                    response.addJS(url: "confetti.js")
                    gamification.score(game: "lab2", login: realLogin.readable)
                } else {
                    let msg = String(format: "Successfully logged as <b>%@</b>. Now your task is to breach the security and authenticate as admin.", login)
                    pageBody.assign(["message":msg], inNest: "info")
                }
            } else {
                loginTemplate.assign(["path":request.path], inNest: "unauthorized")
            }
            
            pageBody["content"] = loginTemplate
            response.body = pageBody
            return .ok(.html(response))
        }
    }
}
