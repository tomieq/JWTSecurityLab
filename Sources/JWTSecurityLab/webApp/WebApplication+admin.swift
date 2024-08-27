//
//  WebApplication+admin.swift
//  JWTSecurityLab
//
//  Created by Tomasz KUCHARSKI on 27/08/2024.
//
import Template
import Swifter

extension WebApplication {
    
    func readableTime(_ seconds: Int) -> String {
        return "\(seconds / 60) min \(seconds % 60) s"
    }
    
    func setupPanel() {
        server.get["results"] = { [unowned self] request, _ in
            let response = mainTemplate
            let page = self.bodyTemplate
            
            let panel = Template.cached(relativePath: "templates/panel.tpl.html")
            let table = Template.cached(relativePath: "templates/table.tpl.html")
            
            ["lab1", "lab2"].forEach { name in
                guard let game = (gamification.games.first{ $0.name == name }) else { return }
                table.reset()
                game.users.enumerated().forEach { (index, user) in
                    table.assign([
                        "position": index + 1,
                        "login": user.login,
                        "time": readableTime(Int(user.finished.timeIntervalSince1970 - game.started.timeIntervalSince1970))
                    ], inNest: "place")
                }
                panel.assign([
                    "name": name,
                    "startDate": game.started.readable,
                    "table": table
                ], inNest: "game")
            }
            
            page["content"] = panel
            
            response.title = "Results"
            response.body = page
            return .ok(.html(response))
        }

        server.get["controls-x50"] = { [unowned self] request, _ in
            let response = mainTemplate
            let page = self.bodyTemplate
            
            let panel = Template.cached(relativePath: "templates/controls.tpl.html")
            
            ["lab1", "lab2"].forEach { game in
                if gamification.isGameStarted(game) {
                    panel.assign(["game": game], inNest: "terminateGame")
                } else {
                    panel.assign(["game": game], inNest: "startGame")
                }
            }
            page["content"] = panel
            
            response.title = "Controls"
            response.addJS(url: "panel.js")
            response.body = page
            return .ok(.html(response))
        }
        
        server.get["panel.js"] = { request, _ in
            let template = Template.cached(relativePath: "templates/panel.tpl.js")
            template["address"] = request.headers.get("host")
            return .ok(.js(template))
        }
        
        server.get["start"] = { [unowned self] request, _ in
            guard let game = request.queryParams.get("game") else {
                return .badRequest(.text("Missing param"))
            }
            gamification.start(game: game)
            return .ok(.js("location.reload();"))
        }
        
        server.get["terminate"] = { [unowned self] request, _ in
            guard let game = request.queryParams.get("game") else {
                return .badRequest(.text("Missing param"))
            }
            gamification.terminate(game: game)
            return .ok(.js("location.reload();"))
        }
    }

}
