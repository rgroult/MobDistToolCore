//
//  PaginationHelper.swift
//  
//
//  Created by Remi Groult on 08/11/2021.
//

import Foundation
import Vapor
import XCTest
@testable import App

@discardableResult
public func paginationRequest<DATA:Content>(path:String, perPage:Int,app:Application, order:PaginationSort?,sortBy:String? = nil,searchby:String? = nil, pageNumber:Int,maxElt:Int,token:String?,firstItemCheck:((DATA?) -> Void)? = nil) throws -> Paginated<DATA>  {
    var query = ["per":"\(perPage)","page":"\(pageNumber)"]
    if let order = order {
        query["orderby"] = order.rawValue
    }
    if let searchBy = searchby {
        query["searchby"] = searchBy
    }
    if let sortBy = sortBy {
        query["sortby"] = sortBy
    }
    let pageResp = try app.clientSyncTest(.GET, path, query,token: token)
    let page = try pageResp.content.decode(Paginated<DATA>.self).wait()
    
    let eltPerPage = min(perPage,maxElt)
    
    XCTAssertEqual(page.page.position.current, pageNumber)
    if eltPerPage > 0 {
        XCTAssertEqual(page.page.position.max, Int(ceil(-1.0 + Double(maxElt) / Double(eltPerPage))))
    }else {
        XCTAssertEqual(page.page.position.max, 0)
    }
    
    firstItemCheck?(page.data.first)
    
    return page

}
