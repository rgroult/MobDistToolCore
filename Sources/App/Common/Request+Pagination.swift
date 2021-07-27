//
//  File.swift
//  
//
//  Created by Remi Groult on 27/07/2021.
//

import Foundation
import MongoKitten
import Vapor

let MappedCursorDefaultPageSize:UInt = 50

enum PaginationSort:String {
    case ascending
    case descending
    func convert(field:String) -> MongoKitten.Sort {
        switch self {
        case .ascending:
                return Sort([(field, SortOrder.ascending)])
        case .descending:
            return Sort([(field, SortOrder.descending)])
        }
    }
}

struct PaginationInfo {
    let additionalStages:[Document]
    let currentPageIndex:Int
    let pageSize:Int
}

extension Request {
    func extractPaginatioInfo(sortFields:[String:String],defaultSort:String)->  PaginationInfo{
       //var stages = [AggregateBuilderStage]()
        var paginateAddition = [Document]()
        let req = self
        
        //page info
        var page = Int((try? req.query.get(UInt.self, at: "page")) ?? 0)
        page = max (0 , page)
        var perPage = Int((try? req.query.get(UInt.self, at: "per")) ?? MappedCursorDefaultPageSize)
        perPage = max (0 , perPage)
        let skipItems = page * perPage
        
        //sort info
        let sortOrder:PaginationSort
        if let sortOrderQuery = try? req.query.get(String.self, at: "orderby"), let sort = PaginationSort(rawValue: sortOrderQuery){
            sortOrder = sort
        }else {
            sortOrder = .descending
        }
        let sortValue = try? req.query.get(String.self, at: "sortby")
        let sortBy:String
        if let field = sortFields[sortValue ?? ""] {
            sortBy = field
        }else {
            sortBy = sortFields[defaultSort]!
        }
        paginateAddition.append(["$sort": sortOrder.convert(field: sortBy).document])
        paginateAddition.append(["$skip": skipItems])
        paginateAddition.append(["$limit": perPage])
      /*  stages.append(.sort(sortOrder.convert(field: sortBy)))
        stages.append(.skip(skipItems))
        stages.append(.limit(perPage))*/
        
        return .init(additionalStages: paginateAddition, currentPageIndex: page,pageSize: perPage)
    }
}
