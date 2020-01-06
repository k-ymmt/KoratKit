//
//  KoratServer.swift
//  KoratKit
//
//  Created by Kazuki Yamamoto on 2019/12/28.
//

import Foundation

private let headerSize: Int64 = 8

public class KoratKitServer {
    private var internalServer: InternalKoratKitServer
    
    private var isStarted: Bool = false
    
    public init(host: String, port: Int) throws {
        self.internalServer = try InternalNIOKoratKitServer(host: host, port: port)
    }
    
    public func start() throws {
        isStarted = true
        defer { isStarted = false }
        print("start server")
        try internalServer.start()
    }
    
    public func send(data: Data) throws {
        var count = Int64(data.count)
        let header = Data(bytes: &count, count: 8)
        try internalServer.send(data: header + data)
    }
    
    public func receive(callback: @escaping (Data) -> Void) {
        internalServer.outputCallback = { [weak self] data in
            guard let self = self else {
                return
            }

            for received in self.parse(source: data) {
                callback(received)
            }
        }
    }
    
    public func error(callback: @escaping (Error) -> Void) {
        internalServer.errorCallback = callback
    }
    
    private func parse(source: Data) -> [Data] {
        var buffer: [Data] = []
        var start: Int64 = 0
        var end: Int64 = start + headerSize
        let count = source.count
        
        while end <= count {
            let header = source[start..<end]
            let length = header.withUnsafeBytes { (buffer) -> Int64 in
                buffer.load(as: Int64.self)
            }
            
            let data = source[end..<end + length]
            buffer.append(data)
            start = end + length
            end = start + headerSize
        }
        
        return buffer
    }
}

protocol InternalKoratKitServer {
    var outputCallback: ((Data) -> Void)? { get set }
    var errorCallback: ((Error) -> Void)? { get set }
    func start() throws
    func send(data: Data) throws
}

public enum KoratInternalServerError: Error {
    case serverInitializeError(message: String)
    case connectionFailure(message: String)
    case invalidData(data: Data, message: String)
}

extension String {
    init(errorNumber: Int32) {
        guard let code = POSIXErrorCode(rawValue: errorNumber) else {
            self = "unknown"
            return
        }

        let error = POSIXError(code)
        
        self = "\(error.code.rawValue  ): \(error.localizedDescription)"
    }
}
