//
//  MdtFileLogger.swift
//  App
//
//  Created by Rémi Groult on 25/02/2019.
//

import Vapor

extension LogLevel:CaseIterable{
    public static var allCases:[LogLevel] = [.verbose,.debug,.info, .warning,.error,.fatal]
    
    var index:Int {
        return LogLevel.allCases.firstIndex(where: { "\($0)" == "\(self)" } ) ?? 0
    }
}

public class MdtFileLogger: Logger {
    static var shared:MdtFileLogger!
    
    let includeTimestamps: Bool
    let fileManager = FileManager.default
    var fileQueue = DispatchQueue.init(label: "MdtFileLogger", qos: .utility)
    var logFileHandle:Foundation.FileHandle?
    var logFileUrl:URL?
    let dateFormatter = DateFormatter()
    lazy var filename:String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY_MM_dd_HH_mm"
        return "MDT_\(dateFormatter.string(from:Date())).log"
    }()
    
    class func initialize(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        shared = try MdtFileLogger(logDirectory: logDirectory, includeTimestamps: includeTimestamps)
        //
    }
    
    func initialize(){
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
    }
    
    required init(logDirectory:String? = nil , includeTimestamps: Bool = false) throws{
        
        let logdir = logDirectory ?? FileManager.default.currentDirectoryPath + "/logs"
        self.includeTimestamps = includeTimestamps
        
        initialize()
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
        self.logFileUrl = logFileUrl
        //go to end on file
        logFileHandle?.seekToEndOfFile()
        guard logFileHandle != nil else { throw "Unable to create log file :\(logFileUrl.absoluteString)"}
        //print("Log file create \(logFileUrl)")
    }
    
    public func log(_ string: String, at level: LogLevel, file: String, function: String, line: UInt, column: UInt) {
       // let fileName = level.description.lowercased() + ".log"
       
        //display file and line only for debug and verbose
        var output:String
        let debugIndex = LogLevel.debug.index
        if level.index <= debugIndex {
             output = "[ \(level.description) ] \(string) (\(file):\(line))"
        }else {
             output = "[ \(level.description) ] \(string)"
        }
        saveToFile(output)
    }
    
    func saveToFile(_ string: String) {
        fileQueue.async {[weak self] in
            var output = string + "\n"
            if let dateFormatter = self?.dateFormatter, self?.includeTimestamps  == true {
                output = "\(dateFormatter.string(from:Date())) " + output
            }

            if let data = output.data(using: .utf8) {
                self?.logFileHandle?.write(data)
            }
        }
    }
    
    func loadTailLines(nbreOfLines:Int, inside eventLoop:EventLoop) -> Future<String>{
        let result = eventLoop.newPromise(of: String.self)
        fileQueue.async {[weak self] in
            do {
               // guard let fd = self?.logFileHandle?.fileDescriptor else { throw "Unable to open File" }
                guard let fileUrl = self?.logFileUrl else { throw "Unable to open File" }
                let numberOfCharactersPerLine = 150
                let readLength:UInt64 = UInt64(nbreOfLines * numberOfCharactersPerLine)
                let readHandle =   try FileHandle(forReadingFrom: fileUrl)//  FileHandle(fileDescriptor:fd,closeOnDealloc:false)

                let fileSize = readHandle.seekToEndOfFile()
                let offset =  fileSize > readLength ? fileSize - readLength : 0 //  max(0, fileSize - readLength)
                readHandle.seek(toFileOffset: offset)
                
                let data = readHandle.readDataToEndOfFile()
                guard let stringValue =  String(data: data, encoding: .utf8) else { throw "Invalid file content" }
                //stringValue = stringValue.components(separatedBy: .newlines).joined(separator: "\n ")
                result.succeed(result: stringValue)
                readHandle.closeFile()
            }catch {
                result.fail(error: error)
            }
        }
        return  result.futureResult
    }
}

extension MdtFileLogger: ServiceType {
    
    public static var serviceSupports: [Any.Type] {
        return [Logger.self]
    }
    
    public static func makeService(for worker: Container) throws -> Self {
        throw "Unable to make empty service"
    }
    
}
