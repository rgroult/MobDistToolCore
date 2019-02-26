//
//  BaseAppTests.swift
//  App
//
//  Created by Rémi Groult on 26/02/2019.
//

import App
import XCTest
import Vapor

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
    override func setUp() {
        do {
            app = try Application.runningAppTest()
        }catch {
            print("Error Starting server:\(error)")
            XCTAssertFalse(true)
        }
    }
    override func tearDown()  {
        do {
        try app.runningServer?.close().wait()
        }catch {
            print("Error Stopping server:\(error)")
            XCTAssertFalse(true)
        }
    }
}
