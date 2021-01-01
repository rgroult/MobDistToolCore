//
//  Config.swift
//  App
//
//  Created by Rémi Groult on 22/02/2019.
//

import Foundation
import Vapor

public struct MdtConfiguration: Codable {
    enum StorageManager: String,Codable {
        case local = "FilesLocalStorage"
        case testing = "TestingStorage"
    }
    var serverListeningPort:Int
    var serverExternalUrl:URL?
    var serverUrl:URL {
        return serverExternalUrl ?? URL(string: "http://localhost:8080")!
    }
    var mongoServerUrl:URL
    private var basePathPrefix:String?
    var pathPrefix:String {
        return basePathPrefix ?? ""
    }
    var jwtSecretToken:String
    //delay (in ms) before login resquest response (limit brut attack).
    var loginResponseDelay:Int
    
    var storageMode:StorageManager
    var storageConfiguration:[String:String]?
    
    var registrationWhiteDomains:[String]?
    var automaticRegistration:Bool
    var smtpConfiguration:[String:String]?
    
    var minimumPasswordStrength:Int
    //[0,1,2,3,4] if crack time is less than
    //[10**2, 10**4, 10**6, 10**8, Infinity]. see https://github.com/exitlive/xcvbnm for more details
    
    var initialAdminEmail:String
    var initialAdminPassword:String
    
    var logDirectory:String? //for production mode : use ./logs if not provided

    var enableCompression:Bool

    var logLevel:String?

    var logLevelAsLevel:LogLevel {
        return LogLevel(stringLiteral: logLevel ?? "info")
    }
    
    static func loadConfig(from filePath:String? = nil, from env:Environment) throws -> MdtConfiguration{
        let configFilePath:String
        if let filePath = filePath {
            configFilePath = filePath
            // configFileContent = try String(contentsOfFile: filePath)
        }else {
            let directory = DirectoryConfig.detect()
            if env == .production {
                configFilePath = "\(directory.workDir)/config/config.json"
                // configFileContent = try  String(contentsOfFile: "\(directory.workDir)/config/config.json")
            }else {
                //use default file for current env
                configFilePath = "\(directory.workDir)/Sources/App/Config/envs/\(env.name)/config.json"
                //configFileContent = try  String(contentsOfFile: "\(directory.workDir)/Sources/App/Config/envs/\(env.name)/config.json")
            }
        }
        print("Loading configuration from \(configFilePath)")
        let configFileContent = try String(contentsOfFile: configFilePath)
        guard var configJson:[String:Any] = try JSONSerialization.jsonObject(with: configFileContent.data(using: .utf8) ?? Data(), options: JSONSerialization.ReadingOptions.mutableContainers) as? [String : Any] else {
            throw "Invalid config file"
            //throw DecodingError.dataCorruptedError(in: configFileContent, debugDescription: "Invalid config file")
        }
        //parse command line argumens values if provided
        //value must be is format "-D<keyname>=value
        var commandArgs = [String:String]()
        let prefix = "-D"
        for arg in env.arguments.filter({ $0.hasPrefix(prefix)}) {
            if let equalSeparatorIndex = arg.firstIndex(of: "=") {
                let keyName = String(arg.substring(to:equalSeparatorIndex).dropFirst(prefix.count))
                let value = arg.substring(from: arg.index(after:equalSeparatorIndex))
                commandArgs[keyName] = value
            }
        }
        //remove -DXXX from env
        env.arguments = env.arguments.filter({ !$0.hasPrefix(prefix)})
        
        let decoder = JSONDecoder()
        //override by authorised [command Line | environnement] values if provided
        //Create empty config to user refexion
        let object = MdtConfiguration.empty
        for case let (label?, value) in Mirror(reflecting: object)
            .children.map({ ($0.label, $0.value) }) {
                //search in env for value "MDT_$label"
                if let envValue =  Environment.get("MDT_\(label)") ?? commandArgs[label] {
                    do {
                        let newValue = try object.convert(from: envValue,into:value)
                        // Int.conver
                        print("Override : \(label), with value: \(envValue)")
                        // newValue = try decoder.decode(Int.self, from: envValue.convertToData())
                        //decoder.decode(type(of:newValue),envValue.data(using: .ascii))
                        configJson[label] =  newValue
                    }catch {
                        print ("Incorrect value type for key MDT_\(label)")
                        throw error
                    }
                }
                //
        }
        
        let mergeConfig = try JSONSerialization.data(withJSONObject: configJson, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        let config = try decoder.decode(MdtConfiguration.self, from: mergeConfig)
        //print("Refexion \(Mirror(reflecting: MdtConfiguration.self))")
        
        return config
    }
    
    /*public init(from decoder: Decoder) throws {
     super.init(decoder)
     print("Check env to missing keys")
     }*/
}

extension MdtConfiguration {
    private static var empty:MdtConfiguration {
        return MdtConfiguration(serverListeningPort: 0, serverExternalUrl: URL(string: "http://host.com")!, mongoServerUrl: URL(string: "mongodb://host")!,basePathPrefix:"/api",  jwtSecretToken: "", loginResponseDelay: 0, storageMode: .testing, storageConfiguration: [String:String](), registrationWhiteDomains: [String](), automaticRegistration: true, smtpConfiguration:[String:String](), minimumPasswordStrength: 0, initialAdminEmail: "", initialAdminPassword: "", logDirectory:"",enableCompression: false)
    }
    
    private func convert<T>(from value:String, into:T) throws -> Any {
        let result:Any?
        switch into {
        case is String, is URL:
            result = value as? T
        case is Int:
            result = Int(value) as? T
        case is Bool:
            result = Bool(value) as? T
            /*  case is URL:
             result = URL(string: value) as? T*/
        case is [String]:
            result = try JSONDecoder().decode([String].self, from: value.convertToData()) as? T
        case is [String:String]:
            result = try JSONDecoder().decode([String:String].self, from: value.convertToData()) as? T
        case is StorageManager:
            guard let storage = (StorageManager(rawValue: value) as? StorageManager)?.rawValue else { throw "Unable to convert \(value) into \(into.self)"}
            result = storage
        default:
            throw "Invalid Value Type \(T.self)"
        }
        guard let objectParsed = result else { throw "Unable to convert \(value) into \(into.self)"}
        return objectParsed
    }
}
//extension MdtConfiguration: Provider {
//    func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
//        return .done(on: container)
//    }
//
//    func register(_ services: inout Services) throws {}
//}
/*
extension MdtConfiguration : ServiceType {
    public static func makeService(for container: Container) throws -> MdtConfiguration {
        throw "Unable to make empty service"
    }
    
    
}*/

struct MdtConfigurationKey: StorageKey {
    typealias Value = MdtConfiguration
}

extension Application {
    func appConfiguration() throws -> MdtConfiguration {
        guard let config = mdtConfiguration else { throw Abort(.internalServerError) }
        return config
    }
    var mdtConfiguration: MdtConfiguration? {
        get {
            return self.storage[MdtConfigurationKey.self]
        }
        set {
            self.storage[MdtConfigurationKey.self] = newValue
        }
    }
}
