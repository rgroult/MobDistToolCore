//
//  File.swift
//  
//
//  Created by gogetta on 23/01/2021.
//

import Foundation
import MongoKitten
import Vapor
import Meow

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


extension FindQueryBuilder {
  /*  func paginate<M: ReadableModel>(for req:Request, model:M.Type, sortFields:[String:String],defaultSort:String,countQuery:EventLoopFuture<Int>) -> EventLoopFuture<Paginated<Element>>{
        return countQuery.flatMap{ count in
            self.paginate(for: req, model:model, sortFields: sortFields,defaultSort:defaultSort, totalCount: count)
        }
    }*/
    
    func paginate<M: ReadableModel,Element:Content>(for req:Request, model:M.Type, sortFields:[String:String],defaultSort:String,findQuery:MongoKittenQuery? = nil,transform: @escaping ((M) -> Element)) -> EventLoopFuture<Paginated<Element>>{
        
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
        
        let collection = req.meow.collection(for: model)
        let query = findQuery?.makeDocument() ?? Document()
        
        return collection.count(where: query).flatMap{ totalCount in
            let pageData = PageData(per: perPage, total: totalCount)
            let maxPosition = max(0, Int(ceil(-1.0 + Double(totalCount) / Double(perPage))))
            let position = Position(current: Int(page), max: maxPosition)
            return self.sort(sortOrder.convert(field: sortBy))
                .skip(skipItems).limit(perPage)
                .decode(M.self)
                .map(transform: transform)
                .allResults()
                .map { elts  -> Paginated<Element>in
                    let pageInfo = PageInfo(position: position, data: pageData)
                    return Paginated (page: pageInfo, data: elts)
                }
           
               // .decode(Element.self)
              //  .getPageResult(position,pageData)
        }
    }
}

/*
extension MappedCursor where Element:Content {
    func getPageResult<Element:Content>(_ position:Position,_ pageData:PageData) -> EventLoopFuture<Paginated<Element>>{
        return allResults().flatMapThrowing({ arrayOfResult in
            let decoder = BSONDecoder()
            let elts = try arrayOfResult.map { document in
                return try decoder.decode(Element.self, from: document)
            }
                
            let pageInfo = PageInfo(position: position, data: pageData)
            return Paginated (page: pageInfo, data: elts)
        })
    }
}
*/
