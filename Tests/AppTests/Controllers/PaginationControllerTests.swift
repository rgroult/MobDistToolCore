//
//  PaginationControllerTests.swift
//  App
//
//  Created by Rémi Groult on 17/10/2019.
//

import Foundation
import Vapor
import XCTest
import Pagination
@testable import App

final class PaginationControllerTests: BaseAppTests {
    
    func testUsersPagination() throws{
        let usersToCreate = 100
        
        for i in 1...usersToCreate {
            
            let user = RegisterDto(email: "test\(String(format: "%03d",i))@test.com", name: "User \(i)", password: "password")
            _ = try register(registerInfo:user,inside:app)
            
        }
        
        let nbreOfUsers = usersToCreate + 1  //admin
        
        //login as superadmin
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        let token = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
        
        // test pagination : begin
        try paginationRequest(path: "/v2/Users", perPage: 30, sort: .descending ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) -> Bool in
            return "test100@test.com" == elt?.email
        }
        // test pagination : middle
        try paginationRequest(path: "/v2/Users", perPage: 30, sort: .descending ,pageNumber: 2, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) -> Bool in
            return "test040@test.com" == elt?.email
        }
        // test pagination : end
        try paginationRequest(path: "/v2/Users", perPage: 30, sort: .descending ,pageNumber: 3, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) -> Bool in
            return "test010@test.com" == elt?.email
        }
        
        // test pagination : after
        try paginationRequest(path: "/v2/Users", perPage: 30, sort: .descending ,pageNumber: 5, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) -> Bool in
            return true
        }
        
        // test pagination : sort ascending
        try paginationRequest(path: "/v2/Users", perPage: 30, sort: .ascending ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) -> Bool in
            return configuration.initialAdminEmail == elt?.email
        }
    }

    
    func paginationRequest<DATA:Content>(path:String, perPage:Int,sort:PaginationSort?, pageNumber:Int,maxElt:Int,token:String,firstItemCheck:((DATA?) -> Bool)) throws {
        var query = ["per":"\(perPage)","page":"\(pageNumber)"]
        if let sort = sort {
            query["orderby"] = sort.rawValue
        }
        let pageResp = try app.clientSyncTest(.GET, path, nil, query,token: token)
        let page = try pageResp.content.decode(Paginated<DATA>.self).wait()
        
        XCTAssertEqual(page.page.position.current, pageNumber)
        XCTAssertEqual(page.page.position.max, Int(ceil(-1.0 + Double(maxElt) / Double(perPage))))
        let dataCount:Int
        if pageNumber <= page.page.position.max {
             dataCount = pageNumber == page.page.position.max ? maxElt%perPage : perPage
            
        }else {
           dataCount = 0
        }
        XCTAssertEqual(page.data.count,dataCount )
        XCTAssertTrue(firstItemCheck(page.data.first))
    }
}
