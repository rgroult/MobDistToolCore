//
//  File.swift
//  
//
//  Created by Remi Groult on 27/07/2021.
//

import Foundation
import MongoKitten
import Vapor

struct Total:Codable {
    let count:Int
}
struct PaginationResult<T:Codable>:Codable {
    let data:[T]
    let totalObjects:[Total]
    var total: Int {
        return totalObjects.first?.count ?? 0
    }
    
    public func map<Element>(_ transform: (T) throws -> Element) rethrows -> PaginationResult<Element> {
        return PaginationResult<Element>(data: try data.map{try transform($0)}, totalObjects:totalObjects)
    }
    
    func pageOutput(from info:PaginationInfo) -> Paginated<T> where T:Content{
        let pageData = PageData(per: info.pageSize, total: total)
        let maxPosition = max(0, Int(ceil(-1.0 + Double(total) / Double(info.pageSize))))
        let position = Position(current: info.currentPageIndex, max: maxPosition)
        return Paginated(page: .init(position: position, data: pageData), data: data)
    }
    static func emptyOutput(from info:PaginationInfo) -> Paginated<T> where T:Content{
        let pageData = PageData(per: info.pageSize, total: 0)
        let position = Position(current: info.currentPageIndex, max: 0)
        return Paginated(page: .init(position: position, data: pageData), data: [])
    }
}
