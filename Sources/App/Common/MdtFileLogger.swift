//
//  MdtFileLogger.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor

public final class MdtFileLogger: Logger {
    static var shared:MdtFileLogger!
    
    let includeTimestamps: Bool
    let fileManager = FileManager.default
    let fileQueue = DispatchQueue.init(label: "MdtFileLogger", qos: .utility)
    var logFileHandle:Foundation.FileHandle?
    
    class func initialize(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        shared = try MdtFileLogger(logDirectory: logDirectory, includeTimestamps: includeTimestamps)
        //
    }
    
    /*var fileHandles = [URL: Foundation.FileHandle]()
    lazy var logDirectoryURL: URL? = {
        var baseURL: URL?
        #if os(macOS)
        /// ~/Library/Caches/
        if let url = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            baseURL = url
        } else { print("Unable to find caches directory.") }
        #endif
        #if os(Linux)
        baseURL = URL(fileURLWithPath: "/var/log/")
        #endif
        
        /// Append executable name; ~/Library/Caches/executableName/ (macOS),
        /// or /var/log/executableName/ (Linux)
        do {
            if let executableURL = baseURL?.appendingPathComponent(executableName, isDirectory: true) {
                try fileManager.createDirectory(at: executableURL, withIntermediateDirectories: true, attributes: nil)
                baseURL = executableURL
            }
        } catch { print("Unable to create \(executableName) log directory.") }
        
        return baseURL
    }()
    */
    private init(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY_MM_dd_HH_mm"
        let logFileUrl = baseURL.appendingPathComponent("MDT_\(dateFormatter.string(from:Date())).log", isDirectory: false)
        
        //create file
        try createLogFileIfNeeded(fileName: logFileUrl.path)
        
        logFileHandle = try FileHandle(forWritingTo: logFileUrl)
        guard logFileHandle != nil else { throw "Unable to create log file :\(logFileUrl.absoluteString)"}
        print("Log file create \(logFileUrl)")
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
      /*  guard let baseURL = logDirectoryURL else { return }
        
        fileQueue.async {
            let url = baseURL.appendingPathComponent(fileName, isDirectory: false)
            let output = string + "\n"
            
            do {
                if !self.fileManager.fileExists(atPath: url.path) {
                    try output.write(to: url, atomically: true, encoding: .utf8)
                } else {
                    let fileHandle = try self.fileHandle(for: url)
                    fileHandle.seekToEndOfFile()
                    if let data = output.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                }
            } catch {
                print("SimpleFileLogger could not write to file \(url).")
            }
        }*/
    }
    
    /// Retrieves an opened FileHandle for the given file URL,
    /// or creates a new one.
//    func fileHandle(for url: URL) throws -> Foundation.FileHandle {
//        if let opened = fileHandles[url] {
//            return opened
//        } else {
//            let handle = try FileHandle(forWritingTo: url)
//            fileHandles[url] = handle
//            return handle
//        }
//    }
    
}

extension MdtFileLogger: ServiceType {
    
    public static var serviceSupports: [Any.Type] {
        return [Logger.self]
    }
    
    public static func makeService(for worker: Container) throws -> MdtFileLogger {
        return try MdtFileLogger()
    }
    
}
