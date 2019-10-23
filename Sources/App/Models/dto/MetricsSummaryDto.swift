//
//  MetricsSummaryDto.swift
//  App
//
//  Created by Rémi Groult on 23/10/2019.
//

import Foundation
import Vapor

struct MetricsSummaryDto: Codable {
    let UsersCount:Int?
    let ApplicationsCount:Int?
    let ArtifactsCount:Int?
}

extension MetricsSummaryDto {
    static func sample() -> MetricsSummaryDto {
        return MetricsSummaryDto( UsersCount: 1, ApplicationsCount:1,ArtifactsCount:1 )
    }
}

extension MetricsSummaryDto: Content {}
