//
//  MdtActivityFileLogger.swift
//  App
//
//  Created by Rémi Groult on 21/10/2019.
//

import Foundation

import Vapor

public final class MdtActivityFileLogger: MdtFileLogger {
    
   // static var sharedActivity:MdtActivityFileLogger!
    /*
    required convenience init(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        try super.init(logDirectory: logDirectory, includeTimestamps: includeTimestamps)
        self.fileQueue = DispatchQueue.init(label: "MdtActivityFileLogger", qos: .utility)
        self.filename = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY_MM_dd_HH_mm"
            return "MDT_Activity_\(dateFormatter.string(from:Date())).activity"
        }()
    }*/
    override func initialize(){
        super.initialize()
        self.fileQueue = DispatchQueue.init(label: "MdtActivityFileLogger", qos: .utility)
        self.filename = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY_MM_dd"
            return "MDT_Activity_\(dateFormatter.string(from:Date())).activity"
        }()
    }
    /*
    override class func initialize(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        sharedActivity = try MdtActivityFileLogger(logDirectory: logDirectory, includeTimestamps: includeTimestamps)
        //
    }*/
}

extension  MdtActivityFileLogger: ActivityLogger {
    func track(event: ActivityEvent) {
       // print("Track \(event)")
        let description = "- \(event.description())"
        saveToFile(description)
           // TODO
       }
}

struct MdtActivityFileLoggerKey: StorageKey {
    typealias Value = MdtActivityFileLogger
}

extension Application {
    var activityLogger: MdtActivityFileLogger? {
        get {
            self.storage[MdtActivityFileLoggerKey.self]
        }
        set {
            self.storage[MdtActivityFileLoggerKey.self] = newValue
        }
    }
}

extension Request {
    var activityLogger: MdtActivityFileLogger? {
        return application.activityLogger
    }
}
