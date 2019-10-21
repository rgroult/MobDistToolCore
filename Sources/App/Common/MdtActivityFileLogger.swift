//
//  MdtActivityFileLogger.swift
//  App
//
//  Created by Rémi Groult on 21/10/2019.
//

import Foundation

import Vapor

public final class MdtActivityFileLogger: MdtFileLogger {
    
    required convenience init(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        try self.init(logDirectory: logDirectory, includeTimestamps: includeTimestamps)
        self.fileQueue = DispatchQueue.init(label: "MdtActivityFileLogger", qos: .utility)
        self.filename = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY_MM_dd_HH_mm"
            return "MDT_Activity_\(dateFormatter.string(from:Date())).activity"
        }()
    }
}