//
//  Config.swift
//  App
//
//  Created by Rémi Groult on 22/02/2019.
//

import Foundation
import Vapor

struct MdtConfiguration: Codable {
    enum StorageManager: String,Codable {
        case local = "FilesLocalStorage"
        case testing = "TestingStorage"
    }
    var serverListeningPort:Int
    var serverExternalUrl:URL
    var mongoServerUrl:URL
    var jwtSecretToken:String?
    //delay (in ms) before login resquest response (limit brut attack).
    var loginResponseDelay:Int
    
    var storageMode:StorageManager
    var storageConfiguration:[String:String]?
    
    var registrationWhiteDomains:[String]?
    var automaticRegistration:Bool
    //[0,1,2,3,4] if crack time is less than
    //[10**2, 10**4, 10**6, 10**8, Infinity]. see https://github.com/exitlive/xcvbnm for more details
    var minimumPasswordStrength:Int
    
    var initialAdminEmail:String
    var initialAdminPassword:String
    
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
        
        let decoder = JSONDecoder()
        
        //override by authorised environnement values if provided
        //Create empty config to user refexion
        let object = MdtConfiguration.empty
        for case let (label?, value) in Mirror(reflecting: object)
            .children.map({ ($0.label, $0.value) }) {
                //search in env for value "MDT_$label"
                if let envValue = Environment.get("MDT_\(label)") {
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
        return MdtConfiguration(serverListeningPort: 0, serverExternalUrl: URL(string: "http://host.com")!, mongoServerUrl: URL(string: "mongodb://host")!, jwtSecretToken: nil, loginResponseDelay: 0, storageMode: .testing, storageConfiguration: nil, registrationWhiteDomains: nil, automaticRegistration: true, minimumPasswordStrength: 0, initialAdminEmail: "", initialAdminPassword: "")
    }
    
    private func convert<T>(from value:String, into:T) throws -> T {
        let result:T?
        switch into {
            case is String, is URL:
               result = value as? T
        case is Int:
            result = Int(value) as? T
      /*  case is URL:
            result = URL(string: value) as? T*/
        case is [String]:
            result = try JSONDecoder().decode([String].self, from: value.convertToData()) as? T
        case is [String:String]:
            result = try JSONDecoder().decode([String:String].self, from: value.convertToData()) as? T
        default:
            throw "Invalid Value Type \(T.self)"
        }
        guard let objectParsed = result else { throw "Unable to convert \(value) into \(into.self)"}
        return objectParsed
    }
}

//final Map defaultConfig = {
//    MDT_SERVER_PORT:8080,
//    MDT_SERVER_URL:"http://localhost:8080",
//    MDT_DATABASE_URI:"mongodb://localhost:27017/mdt_dev",
//    MDT_STORAGE_NAME:"yes_storage_manager",
//    MDT_STORAGE_CONFIG:{},
//    MDT_SMTP_CONFIG:{},
//    MDT_REGISTRATION_WHITE_DOMAINS:[],
//    MDT_REGISTRATION_NEED_ACTIVATION:"false",
//    MDT_TOKEN_SECRET:"secret token dsfsxfsfsqd%%Qsdqs",
//    MDT_LOG_DIR:"",
//    MDT_LOG_TO_CONSOLE:"true",
//    MDT_SYSADMIN_INITIAL_PASSWORD:"sysadmin",
//    MDT_SYSADMIN_INITIAL_EMAIL:"admin@localhost.com",
//    //delay (in ms) before login resquest response (limit brut attack).
//    MDT_LOGIN_DELAY:"0",
//    // minimum strength password required
//    //[0,1,2,3,4] if crack time is less than
//    /// [10**2, 10**4, 10**6, 10**8, Infinity]. see https://github.com/exitlive/xcvbnm for more details
//    MDT_PASSWORD_MIN_STRENGTH:"0",
//    MDT_IPA_EXTRACT_USING_UNZIP:"false",
//    MDT_AAPT_FULL_PATH:"aapt" //search in path
//};
