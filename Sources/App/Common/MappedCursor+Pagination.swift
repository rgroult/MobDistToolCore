//
//  MappedCursor+Pagination.swift
//  App
//
//  Created by Rémi Groult on 15/10/2019.
//

import Meow
import Vapor
import Pagination

let MappedCursorDefaultPageSize = 10

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

extension MappedCursor  where Element:Content {
    
    func paginate(for req:Request, sortFields:[String:String]) -> Future<Paginated<Element>>{
        //extract "page" and "per" parameters
        
        //page info
        var page = (try? req.query.get(Int.self, at: "page")) ?? 0
        page = max (0 , page)
        let perPage = (try? req.query.get(Int.self, at: "per")) ?? MappedCursorDefaultPageSize
        let skipItems = page * perPage
        
        //search info
        //let searchValue = try? req.query.get(String.self, at: "search")
        
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
            sortBy = sortFields.values.first!
        }
        
        //return manager.collection(for: M.self).count(query)
        
    
        return self.collection.count().flatMap{ count in
            let pageData = PageData(per: perPage, total: count)
            let position = Position(current: page, max: Int(ceil(Double(count) / Double(perPage))) - 1 /* start indice is 0 */)
            return self.sort(sortOrder.convert(field: sortBy)).skip(skipItems).limit(perPage)
                .getPageResult(position,pageData)
        }
    }
    
    func getPageResult(_ position:Position,_ pageData:PageData) -> Future<Paginated<Element>>{
        return getAllResults().map({ arrayOfResult in
            let pageInfo = PageInfo(position: position, data: pageData)
            return Paginated (page: pageInfo, data: arrayOfResult)
        })
    }
}
