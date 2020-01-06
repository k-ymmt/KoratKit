//
//  Logger.swift
//  KoratKit
//
//  Created by Kazuki Yamamoto on 2020/01/03.
//

import Foundation
import Logging

private let host = "localhost"
private let port = 8555

public class LoggingServer {
    public static let `default` = LoggingServer()
    
    private var server: KoratKitServer?
    
    private init() {
        DispatchQueue.global().async {
            do {
                self.server = try KoratKitServer(host: host, port: port)
                try self.server?.start()
                print("logging start")
            } catch {
                print(error)
            }
        }
    }
    
    func send(_ data: Log) {
        do {
            try server?.send(data: try data.serializedData())
        } catch {
            print(error)
        }
    }
}

public struct KoratKitLogHandler {
    public var logLevel: Logging.Logger.Level = .debug
    public var metadata: Logging.Logger.Metadata = [:]
    
    private let label: String
    private let server: LoggingServer
    
    public init(label: String) {
        self.server = LoggingServer.default
        self.label = label
    }
}

extension KoratKitLogHandler: LogHandler {
    
    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
        var logData = Log()
        let date = Date()
        logData.time = date.timeIntervalSince1970
        logData.level = Log.LogLevel(level)
        logData.message = message.description
        logData.source = Log.Source(file: file, function: function, line: Int(line))
        
        server.send(logData)
    }
    
    public subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get {
            self.metadata[metadataKey]
        }
        set(newValue) {
            self.metadata[metadataKey] = newValue
        }
    }
}

extension Log.LogLevel {
    init(_ level: Logger.Level) {
        switch level {
        case .trace:
            self = .trace
        case .debug:
            self = .debug
        case .info:
            self = .info
        case .notice:
            self = .notice
        case .warning:
            self = .warning
        case .error:
            self = .error
        case .critical:
            self = .critical
        }
    }
}

extension Log.Source {
    init(file: String, function: String, line: Int) {
        self.file = file
        self.function = function
        self.line = Int32(line)
    }
}
