//
//  MdtFileLogger.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor

public class MdtFileLogger: Logger {
    static var shared:MdtFileLogger!
    
    let includeTimestamps: Bool
    let fileManager = FileManager.default
    var fileQueue = DispatchQueue.init(label: "MdtFileLogger", qos: .utility)
    var logFileHandle:Foundation.FileHandle?
    lazy var filename:String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY_MM_dd_HH_mm"
        return "MDT_\(dateFormatter.string(from:Date())).log"
    }()
    
    class func initialize(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        shared = try MdtFileLogger(logDirectory: logDirectory, includeTimestamps: includeTimestamps)
        //
    }
    
    required init(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        let logdir = logDirectory ?? FileManager.default.currentDirectoryPath + "/logs"
        self.includeTimestamps = includeTimestamps
        
        //create log file
        try createLogFile(logDirectory: logdir)
    }
    
    deinit {
        logFileHandle?.closeFile()
    }
    
    private func createLogFileIfNeeded(fileName:String) throws{
        let directory = URL(fileURLWithPath: fileName).deletingLastPathComponent().path
        
        let fileManager = FileManager.default
        var isDirectory:ObjCBool = false
        if !fileManager.fileExists(atPath: fileName, isDirectory: &isDirectory) {
            //create directory if needed
            try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            
            //create file
            guard fileManager.createFile(atPath: fileName, contents: nil, attributes: nil) else { throw "\(fileName) unable to create file" }
            
          //  try fileManager.createDirectory(atPath: fileName, withIntermediateDirectories: true, attributes: nil)
        }else {
            //check if it'a a file
            guard !isDirectory.boolValue else { throw "\(fileName) does not seems to be a file"}
        }
    }
    
    private func createLogFile(logDirectory:String) throws {
        let baseURL = URL(fileURLWithPath:logDirectory)
        //let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "YYYY_MM_dd_HH_mm"
        let logFileUrl = baseURL.appendingPathComponent(filename, isDirectory: false)
        
        //create file
        try createLogFileIfNeeded(fileName: logFileUrl.path)
        
        logFileHandle = try FileHandle(forWritingTo: logFileUrl)
        guard logFileHandle != nil else { throw "Unable to create log file :\(logFileUrl.absoluteString)"}
        //print("Log file create \(logFileUrl)")
    }
    
    public func log(_ string: String, at level: LogLevel, file: String, function: String, line: UInt, column: UInt) {
        let fileName = level.description.lowercased() + ".log"
        var output = "[ \(level.description) ] \(string) (\(file):\(line))"
        if includeTimestamps {
            output = "\(Date() ) " + output
        }
        saveToFile(output, fileName: fileName)
    }
    
    func saveToFile(_ string: String, fileName: String) {
        fileQueue.async {[weak self] in
            let output = string + "\n"
            if let data = output.data(using: .utf8) {
                self?.logFileHandle?.write(data)
            }
        }
    }
    /*
    func loadTailLines(nbreOfLines:Int) -> Future<String>{
        
    }*/
}

extension MdtFileLogger: ServiceType {
    
    public static var serviceSupports: [Any.Type] {
        return [Logger.self]
    }
    
    public static func makeService(for worker: Container) throws -> Self {
        return try Self.init()
    }
    
}
