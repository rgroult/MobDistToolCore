import App
import XCTest
import MongoKitten

final class AppTests: XCTestCase {
    func testNothing() throws {
        // Add your tests here
        XCTAssert(true)
    }
    
    func testDb() throws {
        let db = try Database.synchronousConnect("mongodb://localhost:27017/mobdisttool")
        let applications = db["MDTApplication"]
        
        try applications.find()
            .map { document in
                print(document)
            }.getFirstResult()
        .wait()
    }

    static let allTests = [
        ("testNothing", testNothing)
    ]
}
