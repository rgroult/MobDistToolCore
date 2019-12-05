//
//  DeployScriptTests.swift
//  AppTests
//
//  Created by Rémi Groult on 25/11/2019.
//

import Foundation
import Vapor
import XCTest
import Pagination
@testable import App

final class DeployScriptTests: BaseAppTests {
    //MARK: - Tests
    private var iOSApiKey:String!
    private var androidApiKey:String!
    private var token:String?
    private var pythonPath:String!

    override func setUp() {
        super.setUp()
        //register user
        _ = try? register(registerInfo: userIOS, inside: app)
        //login
        token = try? login(withEmail: userIOS.email, password: userIOS.password, inside: app).token
        do {
            iOSApiKey = try ApplicationsControllerTests.createApp(with: appDtoiOS, inside: app,token: token).apiKey
            androidApiKey = try ApplicationsControllerTests.createApp(with: appDtoAndroid, inside: app,token: token).apiKey
            
            let dirConfig = DirectoryConfig.detect()
            let filePath = dirConfig.workDir+"Ressources/python.path"
            pythonPath = String(data: try Data(contentsOf: URL(fileURLWithPath: filePath)),encoding: .utf8)
            pythonPath = pythonPath.trimmingCharacters(in: .newlines)
        }catch{
            print("Error \(error)")
        }
        
    }
    
    func callScript(apiKey:String, args:[String],isSucess:Bool = true){
        let config = try! app.make(MdtConfiguration.self)
        //call http://localhost:8080/great/v2/Artifacts/92f5cb62-610b-4a4c-9777-b2f0b4b1171e/deploy | | python -
        #if os(Linux)
        #else
        let curlTask = Process()
        curlTask.launchPath = "/usr/bin/curl"
        curlTask.arguments = ["-Ls","http://localhost:8081\(config.pathPrefix)/v2/Artifacts/\(apiKey)/deploy"]
        let pipe = Pipe()
        curlTask.standardOutput = pipe
        
        let pythonTask = Process()
        //pythonTask.launchPath = "/usr/bin/python3"
        pythonTask.launchPath = pythonPath
        pythonTask.standardInput = pipe
        pythonTask.arguments = ["-"] + args
        let outputPipe = Pipe()
        pythonTask.standardOutput = outputPipe
        
        do {
            #if os(Linux)
            try curlTask.run()
            try pythonTask.run()
            #else
            curlTask.launch()
            pythonTask.launch()
            #endif
            
            curlTask.waitUntilExit()
            pythonTask.waitUntilExit()
            let status = pythonTask.terminationStatus
            
            print("Deploy result : \(String( data: outputPipe.fileHandleForReading.readDataToEndOfFile(),encoding:.utf8) ?? "")")
            if isSucess {
                XCTAssertEqual(status, 0)
            }else {
                XCTAssertNotEqual(status, 0)
            }
            
            
           //  let plistBinary = outputPipe.fileHandleForReading.readDataToEndOfFile()
           //  var plistFormat = PropertyListSerialization.PropertyListFormat.binary
        }catch {
            XCTAssertNil(error)
        }
        #endif
    }
    
    func getIpaAbsoluteFilePath() -> String {
        let dirConfig = DirectoryConfig.detect()
        let filePath = dirConfig.workDir+"Ressources/calculator.ipa"
        return filePath
    }
    
    func testCallDeleteKO(){
        callScript(apiKey: iOSApiKey, args: ["DELETE","--latest","fullParameters"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["DELETE","fullParameters"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["DELETE","fullParameters","-name", "test1"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["DELETE","fullParameters","-name", "test1","-version","A.R.Y"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["DELETE","fromFile"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["DELETE","fromFile", "nofile.json"],isSucess: false)
    }
    
    func testCallAddKO(){
        callScript(apiKey: iOSApiKey, args: ["ADD","--latest","fullParameters"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["ADD","fullParameters"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["ADD","fullParameters","-name", "test1"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["ADD","fullParameters","-name", "test1","-version","A.R.Y"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["ADD","fromFile"],isSucess: false)
        callScript(apiKey: iOSApiKey, args: ["ADD","fromFile", "nofile.json"],isSucess: false)
    }
    
    func testCallDeleteNotFound(){
        callScript(apiKey: iOSApiKey, args: ["DELETE","--latest","fullParameters","-name", "test1"],isSucess: true)
        callScript(apiKey: iOSApiKey, args: ["DELETE","fullParameters","-name", "test1","-version","A.R.Y","-branch","master"],isSucess: true)
    }
    
    func testCallFullParametersOK(){
        callScript(apiKey: iOSApiKey, args: ["ADD","--latest","fullParameters","-name", "test1", "-file" ,getIpaAbsoluteFilePath()])
        callScript(apiKey: iOSApiKey, args: ["DELETE","--latest","fullParameters","-name", "test1"])
        
        callScript(apiKey: iOSApiKey, args: ["ADD","fullParameters","-name", "test1", "-file" ,getIpaAbsoluteFilePath(),"-version","A.R.Y","-branch","master"])
        callScript(apiKey: iOSApiKey, args: ["DELETE","fullParameters","-name", "test1","-version","A.R.Y","-branch","master"])
    }
    
    func testCallFromFileOK(){
        let dirConfig = DirectoryConfig.detect()
        let configFull = dirConfig.workDir+"Ressources/deployfull.json"
        let configLatest = dirConfig.workDir+"Ressources/deployLatest.json"
        
        callScript(apiKey: iOSApiKey, args: ["ADD","fromFile", configFull],isSucess: true)
        callScript(apiKey: iOSApiKey, args: ["ADD","--latest","fromFile", configLatest],isSucess: true)
        
        callScript(apiKey: iOSApiKey, args: ["DELETE","fromFile", configFull],isSucess: true)
        callScript(apiKey: iOSApiKey, args: ["DELETE","--latest","fromFile", configLatest],isSucess: true)
    }
}
