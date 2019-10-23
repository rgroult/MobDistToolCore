//
//  ActivityController+Routing.swift
//  App
//
//  Created by Rémi Groult on 22/10/2019.
//

import Vapor

extension ActivityController {
    enum Verb {
        case trackingActivity
        case logsActivity
        case summary
        var uri:String {
            switch  self {
            case .trackingActivity:
                return "activity"
            case .summary:
                return "summary"
            case .logsActivity:
                return "logs"
            }
        }
    }
    
    func configure(with router: Router, and protectedRouter:Router){
        let protectedActivityRouter = protectedRouter.grouped("\(controllerVersion)/\(pathPrefix)")
        protectedActivityRouter.get(Verb.trackingActivity.uri, use : self.activity)
        protectedActivityRouter.get(Verb.summary.uri, use : self.summary)
        protectedActivityRouter.get(Verb.logsActivity.uri, use : self.logs)
    }
}
