import App
import XCTest
import Vapor

final class AppTests: BaseAppTests {
    //let droplet = try! Droplet.testable()
    
  /*  private var app:Application!
    
    override func setUp() {
        do {
            app = try Application.runningAppTest()
        }catch {
            print("Error Starting server:\(error)")
            XCTAssertFalse(true)
        }
    }*/
    
    func testNothing() throws {
        // Add your tests here
        XCTAssert(true)
    }
    
//    func testDb() throws {
//        let db = try Database.synchronousConnect("mongodb://localhost:27017/mobdisttool")
//        let applications = db["MDTApplication"]
//
//        try applications.find()
//            .map { document in
//                print(document)
//            }.getFirstResult()
//        .wait()
//    }

    static let allTests = [
        ("testNothing", testNothing)
    ]

    func testLoginOK() throws {
        let email = "admin@localhost.com"
        let loginJSON = """
            {
                "email": "\(email)",
                "password": "1234"
            }
        """
        
       // let body = try loginJSON.convertToHTTPBody()
        try app.clientTest(.POST, "/v2/Users/login", loginJSON){ res in
            XCTAssertNotNil(res)
           // let token = res.content.get(String.self, at: "token")
            print(res.body.string)
            let loginResp = try res.content.decode(LoginRespDto.self)
            XCTAssertEqual(loginResp.email, email)
            XCTAssertEqual(loginResp.name, "admin")
            print(loginResp)
        }
    }
    
    
//    func testClientItunesAPI() throws {
//        let app = try Application()
//        let client = try app.make(Client.self)
//        let res = try client.send(.GET, to: "http://localhost:8080/v2/Users/me").wait()
//        //let res = try client.send(.GET, to: "https://itunes.apple.com/search?term=mapstr&country=fr&entity=software&limit=1").wait()
//        let data = res.http.body.data ?? Data()
//        print("REsult :\(String(data: data, encoding: .ascii))")
//        XCTAssertEqual(String(data: data, encoding: .ascii)?.contains("iPhone"), true)
//        }
    
    func ttestParameter() throws {
//        let app = try Application.runningTest(port: 8081) { router in
//            router.get("hello", String.parameter) { req in
//                return try req.parameters.next(String.self)
//            }
//
//            router.get("raw", String.parameter, String.parameter) { req in
//                return req.parameters.rawValues(for: String.self)
//            }
//        }
        
        
        try app.clientTest(.GET, "/hello/vapor", equals: "vapor")
        try app.clientTest(.POST, "/hello/vapor", equals: "Not found")
        
        try app.clientTest(.GET, "/raw/vapor/development", equals: "[\"vapor\",\"development\"]")
    }
    
}

