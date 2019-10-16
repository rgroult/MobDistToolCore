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
extension MappedCursor  where Element:Content {
    
    func paginate(for req:Request) -> Future<Paginated<Element>>{
        //extract "page" and "per" parameters
        var page = (try? req.query.get(Int.self, at: "page")) ?? 0
        page = max (0 , page)
        let perPage = (try? req.query.get(Int.self, at: "per")) ?? MappedCursorDefaultPageSize
        
        let skipItems = page * perPage
        
        return self.collection.count().flatMap{ count in
            let pageData = PageData(per: perPage, total: count)
            let position = Position(current: page, max: Int(floor(Double(count) / Double(perPage))))
            return self.skip(skipItems).limit(perPage)
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
