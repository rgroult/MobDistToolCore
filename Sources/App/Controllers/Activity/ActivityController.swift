//
//  ActivityController.swift
//  App
//
//  Created by Rémi Groult on 22/10/2019.
//

import Foundation
import Swiftgger
import Vapor
import Meow

final class ActivityController:BaseController {
    static let defaultLines = 150
    
    init(apiBuilder:OpenAPIBuilder) {
        super.init(version: "v2", pathPrefix: "Monitoring", apiBuilder: apiBuilder)
    }
    
    func summary(_ req: Request) throws -> EventLoopFuture<MetricsSummaryDto> {
        return try retrieveMandatoryAdminUser(from: req)
        .flatMap({_ in
            let meow = req.meow
            //count number of users, Applications and Artifacts
            let futures = [meow.collection(for: User.self).count(where: []), meow.collection(for: MDTApplication.self).count(where: []) ,meow.collection(for: Artifact.self).count(where: [])]
            return futures.flatten(on: meow.eventLoop)
                .map { counts in
                    return MetricsSummaryDto(UsersCount: counts[0], ApplicationsCount:  counts[1], ArtifactsCount:  counts[2])
                }
        })
    }
    
    func activity(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        let trackingService = try req.application.appActivityLogger()
        return try retrieveMandatoryAdminUser(from: req)
        .flatMap({_ in
            let lines = (try? req.query.get(Int.self, at: "lines")) ?? ActivityController.defaultLines
            //let trackingService = try req.make(MdtActivityFileLogger.self)
            return trackingService.loadTailLines(nbreOfLines: lines, inside: req.eventLoop)
                .map{ MessageDto(message: $0)}
        })
    }
    
    func logs(_ req: Request) throws -> EventLoopFuture<MessageDto> {
        let loggerService = try req.application.appFileLogger()
        return try retrieveMandatoryAdminUser(from: req)
        .flatMap({_ in
            let lines = (try? req.query.get(Int.self, at: "lines")) ?? ActivityController.defaultLines
            //let loggerService = try req.make(MdtFileLogger.self)
            return loggerService.loadTailLines(nbreOfLines: lines, inside: req.eventLoop)
                .map{ MessageDto(message: $0)}
        })
    }
}
