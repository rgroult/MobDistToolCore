//
//  PaginationControllerTests.swift
//  App
//
//  Created by Rémi Groult on 17/10/2019.
//

import Foundation
import Vapor
import XCTest
//import Pagination
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
        
        try populateUsers(nbre: usersToCreate,tempo: 0)
        
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
        try populateUsers(nbre: nbre,tempo: tempo)
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
        try paginationRequest(path: "/v2/Users", perPage: 30, order: .ascending,sortBy:"email" ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
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
    
    func testUsersPaginationSearchByEmail() throws{
        let token = try basePagination(nbre: 20,tempo: 0)
        
        let usersFound = try paginationRequest(path: "/v2/Users", perPage: 30, order: .descending,sortBy:"email",searchby: "test01" ,pageNumber: 0, maxElt: 10, token: token) { (elt:UserDto?) in
            XCTAssertEqual( "test019@test.com" , elt?.email)
        }
        XCTAssertEqual(usersFound.data.count,10)
    }
    
    func testUsersPaginationBigValue() throws{
        let token = try basePagination(nbre: 10,tempo:0.5)
        let nbreOfUsers = 11
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &app.environment)
        try paginationRequest(path: "/v2/Users", perPage: 9999999, order: .ascending,sortBy:"email" ,pageNumber: 0, maxElt: nbreOfUsers, token: token) { (elt:UserDto?) in
             XCTAssertEqual( configuration.initialAdminEmail , elt?.email)
        }
        
    }
    
    
    func loginAsAdmin() throws -> String {
        var environment = app.environment
        let configuration = try MdtConfiguration.loadConfig(from: nil, from: &environment)
        return try login(withEmail: configuration.initialAdminEmail, password: configuration.initialAdminPassword, inside: app).token
    }
    
    func populateApplications(nbre:Int,tempo:Double = 0,token:String) throws{
        for i in 1...nbre {
            if tempo > 0.0 {
                Thread.sleep(forTimeInterval: tempo)
            }
            let platform = i%2 == 0 ? Platform.android : Platform.ios
            let appDto = ApplicationCreateDto(name: "Application\(String(format: "%03d",i))", platform: platform, description: "Desc App", base64IconData: nil, enableMaxVersionCheck: nil)
            _ = try ApplicationsControllerTests.createApp(with: appDto, inside: app, token: token)
        }
    }
    
    func testApplicationsPaginationEmptyResult() throws {
        let token = try loginAsAdmin()
        let apps = try paginationRequest(path: "/v2/Applications", perPage: 20, order: .descending,sortBy:"created" ,searchby:"Application01" , pageNumber: 0, maxElt: 0, token: token) { (elt:ApplicationSummaryDto?) in
        }
        XCTAssertEqual(apps.data.count,0)
    }
    
    func testApplicationsPaginationSearchByName() throws {
        let token = try loginAsAdmin()
        try populateApplications(nbre: 30, tempo: 0, token: token)
        
        let apps = try paginationRequest(path: "/v2/Applications", perPage: 20, order: .descending,sortBy:"created" ,searchby:"Application01" , pageNumber: 0, maxElt: 10, token: token) { (elt:ApplicationSummaryDto?) in
                XCTAssertEqual( "Application019" , elt?.name)
        }
        XCTAssertEqual(apps.data.count,10)
    }
    
    func testApplicationsPaginationSearchByNameInsensitive() throws {
        let token = try loginAsAdmin()
        try populateApplications(nbre: 3, tempo: 0, token: token)
        
        let apps = try paginationRequest(path: "/v2/Applications", perPage: 20, order: .descending,sortBy:"created" ,searchby:"APPLICATION" , pageNumber: 0, maxElt: 10, token: token) { (elt:ApplicationSummaryDto?) in
        }
        XCTAssertEqual(apps.data.count,3)
    }
    
    func testApplicationsPaginationSearchByNameBigValue() throws {
        let token = try loginAsAdmin()
        try populateApplications(nbre: 30, tempo: 0, token: token)
        
        let apps = try paginationRequest(path: "/v2/Applications", perPage: 99999999999999999, order: .descending,sortBy:"created" ,searchby:"Application01" , pageNumber: 0, maxElt: 10, token: token) { (elt:ApplicationSummaryDto?) in
                XCTAssertEqual( "Application019" , elt?.name)
        }
        XCTAssertEqual(apps.data.count,10)
    }
    
    func testApplicationsPaginationSortByName() throws {
        let token = try loginAsAdmin()
        try populateApplications(nbre: 50, token: token)
        
        try paginationRequest(path: "/v2/Applications", perPage: 20, order: .descending,sortBy:"name" , pageNumber: 1, maxElt: 50, token: token) { (elt:ApplicationSummaryDto?) in
            XCTAssertEqual( "Application030" , elt?.name)
        }
    }
    
    func testApplicationsPaginationSortByCreated() throws {
        let token = try loginAsAdmin()
        try populateApplications(nbre: 50, tempo: 0, token: token)
        
        try paginationRequest(path: "/v2/Applications", perPage: 20, order: .descending,sortBy:"created" , pageNumber: 0, maxElt: 50, token: token) { (elt:ApplicationSummaryDto?) in
            XCTAssertEqual( "Application050" , elt?.name)
        }
        
        try paginationRequest(path: "/v2/Applications", perPage: 20, order: .ascending,sortBy:"created" , pageNumber: 0, maxElt: 50, token: token) { (elt:ApplicationSummaryDto?) in
            XCTAssertEqual( "Application001" , elt?.name)
        }
    }
    
    @discardableResult
    func paginationRequest<DATA:Content>(path:String, perPage:Int,order:PaginationSort?,sortBy:String? = nil,searchby:String? = nil, pageNumber:Int,maxElt:Int,token:String,firstItemCheck:((DATA?) -> Void)) throws -> Paginated<DATA>  {
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
        
       /* let dataCount:Int
        (page.page.position.max + 1) * perPage
        
        if pageNumber < page.page.position.max {
             dataCount = pageNumber == page.page.position.max ? maxElt%eltPerPage : eltPerPage
        }else if pageNumber == page.page.position.max {
            dataCount = maxElt - pageNumber
        } else {
           dataCount = 0
        }
        XCTAssertEqual(page.data.count,dataCount )*/
        firstItemCheck(page.data.first)
        
        return page
        //XCTAssertTrue(firstItemCheck(page.data.first))
    }
}
