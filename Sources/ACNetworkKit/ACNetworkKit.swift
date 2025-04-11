// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
import Combine

public enum NetworkError: Error {
    case badURL
    case decodingError
    case unknown(String)
}

public enum ACHTTPMethod: String {
    case get
    case post
    case put
    case delete
}

public protocol APIServicable {
    var baseURL: URL { get }
    var path: String { get }
    var method: ACHTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

@available(iOS 13.0, *)
public protocol NetworkClientProtocol {
    static func request<T: Decodable>(_ request: APIServicable, responseType: T.Type) async throws -> T
}

public class NetworkClient: NetworkClientProtocol {
    
    @available(iOS 13.0, *)
    public static func request<T: Decodable>(_ request: APIServicable, responseType: T.Type) async throws -> T {
        var urlComponents = URLComponents(url: request.baseURL.appendingPathComponent(request.path), resolvingAgainstBaseURL: false)
               urlComponents?.queryItems = request.queryItems

               guard let url = urlComponents?.url else {
                   throw URLError(.badURL)
               }

               var req = URLRequest(url: url)
               req.httpMethod = request.method.rawValue.uppercased()
               req.allHTTPHeaderFields = request.headers
               req.httpBody = request.body

               let (data, response) = try await URLSession.shared.data(for: req)

               guard let httpResponse = response as? HTTPURLResponse,
                     200..<300 ~= httpResponse.statusCode else {
                   throw URLError(.badServerResponse)
               }
               return try JSONDecoder().decode(T.self, from: data)
    }
}
