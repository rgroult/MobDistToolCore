//
//  ArtifactsControllerTests.swift
//  AppTests
//
//  Created by Remi Groult on 03/05/2019.
//

import Foundation
import Vapor
import XCTest
@testable import App

final class ArtifactsContollerTests: BaseAppTests {
    private var iOSApiKey:String?
    
    override func setUp() {
        super.setUp()
        //register user
        _ = try? register(registerInfo: userIOS, inside: app)
        do {
            iOSApiKey = try ApplicationsTests.createApp(with: appDtoiOS, inside: app).apiKey
        }catch{
            print("Error \(error)")
        }
        
    }
    func testCreateWithApiKey(){
        print("Api Key \(iOSApiKey)")
    }
}
