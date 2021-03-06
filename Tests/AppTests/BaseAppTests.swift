//
//  BaseAppTests.swift
//  App
//
//  Created by Rémi Groult on 26/02/2019.
//

import App
import XCTest
import Vapor
import Meow
@testable import App

class BaseAppTests: XCTestCase {
    //let droplet = try! Droplet.testable()
//    private var _app:Application!
//
//    internal var app:Application{
//        if let app = _app {
//            return app
//        }else {
//            do {
//                print("start app")
//                _app = try Application.runningAppTest()
//            }catch {
//                print("Error Starting server:\(error)")
//                XCTAssertFalse(true)
//            }
//
//            //XCTAssertNoThrow(_app = try Application.runningAppTest())
//            return _app
//        }
//    }
    internal var app:Application!
    internal var context:Meow.Context!
    override func setUp() {
        configure()
    }
        
    func configure(with env:Environment? = nil) {
        do {
            app = try Application.runningAppTest(loadingEnv:env)
            context = try app.make(Future<Meow.Context>.self).wait()
            //delete existing data
            try cleanDatabase(into: context)
            //try context.manager.database.drop().wait()
            let config = try app.make(MdtConfiguration.self)
            _ = try createSysAdminIfNeeded(into: context, with: config)
            
        }catch {
            print("Error Starting server:\(error)")
            XCTAssertFalse(true)
        }
    }
    
    private func cleanDatabase(into:Context) throws {
        try context.deleteAll(User.self, where:Query()).wait()
        try context.deleteAll(MDTApplication.self, where:Query()).wait()
        try context.deleteAll(TokenInfo.self, where:Query()).wait()
        try context.deleteAll(Artifact.self, where:Query()).wait()
    }
    
    override func tearDown()  {
        do {
        try app.runningServer?.close().wait()
        //try context.manager.database.drop().wait()
        try context.syncShutdownGracefully()
            context = nil
        }catch {
            print("Error Stopping server:\(error)")
            XCTAssertFalse(true)
        }
    }
}
