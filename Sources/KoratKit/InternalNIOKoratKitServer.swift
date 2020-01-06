//
//  InternalNIOKoratKitServer.swift
//  CNIOAtomics
//
//  Created by Kazuki Yamamoto on 2020/01/02.
//

import Foundation
import NIO

class InternalNIOKoratKitServer: InternalKoratKitServer {
    var outputCallback: ((Data) -> Void)?
    var errorCallback: ((Error) -> Void)?
    
    private let host: String
    private let port: Int
    
    private let channelSyncQueue = DispatchQueue(label: "channelQueue")
    
    private var channels: [ObjectIdentifier: Channel] = [:]
    
    required init(host: String, port: Int) throws {
        self.host = host
        self.port = Int(port)
    }
    
    func start() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let server = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(.init(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { (channel) in channel.pipeline.addHandler(self) }
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        let channel = try server.bind(host: host, port: port).wait()
        try channel.closeFuture.wait()
    }
    
    func send(data: Data) throws {
        guard let (_, firstChannel) = channels.first else {
            return
        }
        var buffer = firstChannel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        for (_, channel) in channels {
            channel.writeAndFlush(buffer, promise: nil)
        }
    }
}

extension InternalNIOKoratKitServer : ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    
    func channelActive(context: ChannelHandlerContext) {
        let channel = context.channel
        channelSyncQueue.async {
            self.channels[ObjectIdentifier(channel)] = channel
        }
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        let channel = context.channel
        channelSyncQueue.async {
            self.channels.removeValue(forKey: ObjectIdentifier(channel))
        }
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let read = unwrapInboundIn(data)
        let count = read.readableBytes
        guard let bytes = read.getBytes(at: 0, length: count) else {
            return
        }
        let data = Data(bytes: bytes, count: count)
        outputCallback?(data)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        errorCallback?(error)
    }
}

extension InternalNIOKoratKitServer {
    func sendString(_ string: String) throws {
        guard let (_, firstChannel) = channels.first else {
            return
        }
        var buffer = firstChannel.allocator.buffer(capacity: string.count)
        buffer.writeString(string)
        for (_, channel) in channels {
            channel.writeAndFlush(buffer, promise: nil)
        }
    }
}
