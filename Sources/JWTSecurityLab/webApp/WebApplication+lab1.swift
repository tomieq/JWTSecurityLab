//
//  WebApplication+lab1.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 27/08/2024.
//
import Template

extension WebApplication {
    func setupLab1() {
        server["/lab1"] = { [unowned self] request, responseHeaders in
            
            let cookieName = "lab1_cookie"
            let secret = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9".data(using: .utf8)!
            let sessionKey = "fd3"
            
            let response = mainTemplate
            let pageBody = self.bodyTemplate
            response.title = "Lab 1"
            
            guard gamification.isGameStarted("lab1") else {
                pageBody["content"] = "Lab1 did not start yet"
                response.body = pageBody
                return .ok(.html(response))
            }
            
            let loginTemplate = Template.cached(relativePath: "templates/loginForm.html")
            let instructions = Template.cached(relativePath: "templates/lab1Instructions.html")
            loginTemplate["instructions"] = instructions
            
            var authorizedLogin: String?
            var realLogin: String?
            
            func html(_ txt: String) -> String {
                "<span class='fw-light'>\(txt)</span>"
            }
            if let token = request.cookies[cookieName] {
                do {
                    let jwt = try JWTdecode(token, algorithm: .hs256(secret))
                    guard let sessionID = jwt.claims[sessionKey] as? String,
                            let previousLogin = sessionManager.loginFor(sessionID: sessionID) else {
                        throw SecError.missingClaim(sessionKey)
                    }
                    authorizedLogin = jwt.claims["user"] as? String
                    realLogin = previousLogin
                } catch is InvalidToken {
                    // simulated bahaviour of CVE-2019-7644
                    let tokenParts = token.split(separator: ".").map{ "\($0)" }
                    if tokenParts.count == 3, let base = "\(tokenParts[0]).\(tokenParts[1])".data(using: .utf8) {
                        let alg = Algorithm.hs256(secret)
                        let signature = base64encode(alg.algorithm.sign(base))
                        let errorMsg = String(format: "Invalid signature. Expected <b>%@</b> got <b>%@</b>",
                                              html(signature),
                                              html(tokenParts[2]))
                        pageBody.assign(["message":errorMsg], inNest: "error")
                    }
                } catch {
                    pageBody.assign(["message":"Failed to decode JWT: \(error)"], inNest: "error")
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
                        let errorMsg = String(format: "Invalid password for user <b>%@</b>.", login)
                        pageBody.assign(["message":errorMsg], inNest: "error")
                    }
                } else {
                    let errorMsg = String(format: "User <b>%@</b> does't exist.", login)
                    pageBody.assign(["message":errorMsg], inNest: "error")
                }
            } else if let _ = request.formData.get("logout") {
                responseHeaders.unsetCookie(name: cookieName)
                pageBody.assign(["message":"Successfully signed out."], inNest: "success")
                authorizedLogin = nil
            }
            

            if let login = authorizedLogin {
                loginTemplate.assign(["login":login], inNest: "authorized")
                if login == "admin" {
                    pageBody.assign(["message":"Job well done \(realLogin.readable)! Contratulations. You have taken over admin's account!"], inNest: "success")
                    response.addJS(url: "confetti.browser.min.js")
                    response.addJS(url: "confetti.js")
                    gamification.score(game: "lab1", login: realLogin.readable)
                } else {
                    let msg = String(format: "Successfully logged as <b>%@</b>. Now your task is to breach the security and authenticate as admin.", login)
                    pageBody.assign(["message":msg], inNest: "info")
                }
            } else {
                loginTemplate.assign([:], inNest: "unauthorized")
            }
            
            pageBody["content"] = loginTemplate
            response.body = pageBody
            return .ok(.html(response))
        }
    }
}
