import OpenAPIRuntime
import VeloxServe
import HTTPTypes
import AsyncAlgorithms  
import Logging

public struct RequestContext: Sendable {
    @TaskLocal public static var current: RequestContext?
    
    public let logger: Logger
}

public final class RouterTransport :  ServerTransport {
    private var router: Router

    public init(router: Router) {
        self.router = router
    }

    public func makeHandler() -> any Handler {
        self.router
    }

    public func register(
        _ handler: @escaping @Sendable (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (
            HTTPResponse, HTTPBody?
        ),
        method: HTTPRequest.Method,
        path: String
    ) {
        self.router.register(method: method, path: path, handler: AnyHandler({ (req: any RequestReader, res: any ResponseWriter) in 
            let request: HTTPRequest = req.request
            let bodySequence: AsyncMapSequence<AnyReadableBody, ArraySlice<UInt8>> = req.body.map { 
                var buffer = $0
                let array = buffer.readBytes(length: buffer.readableBytes)!
                return array[...]
            }

            let reqBodyChannel = AsyncChannel<ArraySlice<UInt8>>()
            let length: HTTPBody.Length = req.headers[.contentLength].flatMap(Int64.init).map { HTTPBody.Length.known($0) } ?? .unknown
            let body = HTTPBody(reqBodyChannel, length: length, iterationBehavior: .single)
            let metadata = ServerRequestMetadata(pathParameters: req.pathParameters.params)
            let logger = req.logger
            
            try await withThrowingTaskGroup(of: (HTTPResponse, HTTPBody?).self) { group in
                group.addTask  { 
                    try await RequestContext.$current.withValue(RequestContext(logger: logger)) {
                        try await handler(request, body, metadata)
                    }
                }

                do {
                    defer {
                        reqBodyChannel.finish()
                    }

                    for try await chunk in bodySequence {
                        await reqBodyChannel.send(chunk)
                    }
                }
                
                let (response, responseBody) = try await group.next()!

                res.status = response.status
                res.headers = response.headerFields
                if let responseBody = responseBody {
                    for try await chunk in responseBody {
                        try await res.writeBodyPart(chunk)
                    }
                }
            }
        }))
    }

}