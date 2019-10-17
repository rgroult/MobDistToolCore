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
    
    func populateUsers(nbre:Int,tempo:Double = 0) throws{
        for i in 1...nbre {
            if tempo > 0.0 {
                Thread.sleep(forTimeInterval: tempo)
            }
            let user = RegisterDto(email: "test\(String(format: "%03d",i))@test.com", name: "User \(i)", password: "password")
            _ = try register(registerInfo:user,inside:app)
        }
    }
    
    func testUsersPagination() throws{
        let usersToCreate = 100
        
        try populateUsers(nbre: usersToCreate)
        
        let nbreOfUsers = usersToCreate + 1  //admin
        
        //login as superadmin
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        let token = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
        
        // test pagination : begin
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?)  in
            XCTAssertEqual("test100@test.com",elt?.email)
        }
        // test pagination : middle
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending ,pageNumber: 2, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
             XCTAssertEqual( "test040@test.com" , elt?.email)
        }
        // test pagination : end
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending ,pageNumber: 3, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
             XCTAssertEqual( "test010@test.com" , elt?.email)
        }
        
        // test pagination : after
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending ,pageNumber: 5, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
           
        }
        
        // test pagination : sort ascending
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .ascending ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
             XCTAssertEqual( configuration.initialAdminEmail , elt?.email)
        }
    }
    
    func basePagination(nbre:Int,tempo:Double = 0)throws -> String {
        try populateUsers(nbre: nbre)
        //login as superadmin
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        return try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
    }
    
    func testUsersPaginationSortByEmail() throws{
        let token = try basePagination(nbre: 10)
        let nbreOfUsers = 11
        
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending,sortBy:"email" ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?)  in
             XCTAssertEqual( "test010@test.com" , elt?.email)
        }
    }
    
    func testUsersPaginationSortByLogin() throws{
        let token = try basePagination(nbre: 10,tempo:0.5)
        let nbreOfUsers = 11
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending,sortBy:"login" ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
             XCTAssertEqual( configuration.initialAdminEmail , elt?.email)
        }
        
    }
    func testUsersPaginationSortByCreatedAscending() throws{
        let token = try basePagination(nbre: 10,tempo:0.5)
        let nbreOfUsers = 11
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .ascending,sortBy:"created" ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
             XCTAssertEqual( configuration.initialAdminEmail ,elt?.email)
        }
    }
    func testUsersPaginationSortByCreatedDescending() throws{
        let token = try basePagination(nbre: 10,tempo:0.5)
        let nbreOfUsers = 11
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending,sortBy:"created" ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
             XCTAssertEqual( "test010@test.com" , elt?.email)
        }
    }
    /*
    func testUsersPaginationSortBy() throws{
        try populateUsers(nbre: 10)
        let nbreOfUsers = 11
        
        //login as superadmin
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        let token = try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
        
        
        
        
        
        
        
       
    }*/
    
    func paginationRequest<DATA:Content>(path:String, perPage:Int,order:PaginationSort?,sortBy:String? = nil, pageNumber:Int,maxElt:Int,token:String,firstItemCheck:((DATA?) -> Void)) throws {
        var query = ["per":"\(perPage)","page":"\(pageNumber)"]
        if let order = order {
            query["orderby"] = order.rawValue
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
        firstItemCheck(page.data.first)
        //XCTAssertTrue(firstItemCheck(page.data.first))
    }
}
