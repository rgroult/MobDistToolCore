//
//  MappedCursor+Pagination.swift
//  App
//
//  Created by Rémi Groult on 15/10/2019.
//

import Meow
import Vapor
import Pagination

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

extension MappedCursor  where Element:Content {
    
    func paginate(for req:Request, sortFields:[String:String],defaultSort:String,countQuery:Future<Int>) -> Future<Paginated<Element>>{
        return countQuery.flatMap{ count in
            self.paginate(for: req, sortFields: sortFields,defaultSort:defaultSort, totalCount: count)
        }
    }
    
    func paginate(for req:Request, sortFields:[String:String],defaultSort:String,findQuery:Query? = nil) -> Future<Paginated<Element>>{
        //extract "page" and "per" parameters
        
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
        
        
        return self.collection.count(findQuery).flatMap{ count in
            let pageData = PageData(per: perPage, total: count)
            let maxPosition = max(0, Int(ceil(-1.0 + Double(count) / Double(perPage))))
            let position = Position(current: Int(page), max: maxPosition /* Int(ceil(Double(count) / Double(perPage)) - 1) *//* start indice is 0 */)
            return self.sort(sortOrder.convert(field: sortBy)).skip(skipItems).limit(perPage)
                .getPageResult(position,pageData)
        }
    }
    
    private func paginate(for req:Request, sortFields:[String:String],defaultSort:String,totalCount:Int) -> Future<Paginated<Element>>{
        //extract "page" and "per" parameters
        
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
        
        let pageData = PageData(per: perPage, total: totalCount)
        let maxPosition = max(0, Int(ceil(-1.0 + Double(totalCount) / Double(perPage))))
        let position = Position(current: page, max: maxPosition /* Int(ceil(Double(count) / Double(perPage)) - 1) *//* start indice is 0 */)
        return self.sort(sortOrder.convert(field: sortBy)).skip(skipItems).limit(perPage)
            .getPageResult(position,pageData)
    }
    
    func getPageResult(_ position:Position,_ pageData:PageData) -> Future<Paginated<Element>>{
        return getAllResults().map({ arrayOfResult in
            let pageInfo = PageInfo(position: position, data: pageData)
            return Paginated (page: pageInfo, data: arrayOfResult)
        })
    }
}
