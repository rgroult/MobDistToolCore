//
//  RandomTests.swift
//  AppTests
//
//  Created by Remi Groult on 10/03/2019.
//

import Foundation

import App
import XCTest
@testable import App

class RandomTests: XCTestCase {
    func testRandom(){
        let randoms = Array(repeating: "", count: 10000)
            .map{_ in return random(128)}
        
        var set = Set(randoms)
        XCTAssertEqual(randoms.count, set.count) // no identical
        
        set.insert(randoms.last!)
        XCTAssertEqual(randoms.count, set.count) // no identical
    }
    
    func checkRandom(length:Int, iterations:Int){
        let randoms = Array(repeating: "", count: iterations)
            .map{_ in return random(length)}
        
        let set = Set(randoms)
        XCTAssertEqual(randoms.count, set.count) // no identical
    }
    
    func testRandom2(){
        checkRandom(length: 32, iterations: 100000)
    }
}
