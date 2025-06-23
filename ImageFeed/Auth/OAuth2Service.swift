import Foundation

final class OAuth2Service {
    static let shared = OAuth2Service()
    private init() {}
    
    private let urlSession = URLSession.shared
    private var currentTask: URLSessionTask?
    private let tokenStorage = OAuth2TokenStorage.shared
    
    func fetchOAuthToken(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        assert(Thread.isMainThread, "This method must be called from main thread")
        
    
        currentTask?.cancel()
        
        guard let request = makeTokenRequest(code: code) else {
            completion(.failure(AuthError.invalidRequest))
            return
        }
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            let result: Result<String, Error>
            
            defer {
                DispatchQueue.main.async {
                    completion(result)
                    self.currentTask = nil
                }
            }
            
            
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    result = .failure(AuthError.requestCancelled)
                } else {
                    result = .failure(error)
                }
                return
            }
            
            
            guard let httpResponse = response as? HTTPURLResponse else {
                result = .failure(AuthError.invalidResponse)
                return
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                result = .failure(self.handleHTTPError(statusCode: httpResponse.statusCode))
                return
            }
            
            
            guard let data = data else {
                result = .failure(AuthError.noData)
                return
            }
            
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let tokenResponse = try decoder.decode(OAuthTokenResponseBody.self, from: data)
                self.tokenStorage.token = tokenResponse.accessToken
                result = .success(tokenResponse.accessToken)
            } catch {
                result = .failure(AuthError.tokenDecodingFailed)
            }
        }
        
        currentTask = task
        task.resume()
    }
    
    private func makeTokenRequest(code: String) -> URLRequest? {
        let baseURL = "https://unsplash.com/oauth/token"
        
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code")
        ]
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request
    }
    
    private func handleHTTPError(statusCode: Int) -> AuthError {
        switch statusCode {
        case 400: return .invalidRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 500...599: return .serverError
        default: return .unexpectedStatusCode(statusCode)
        }
    }
}

// Внутренние типы для OAuth2Service
extension OAuth2Service {
    private struct Constants {
        static let accessKey = "{YOUR_ACCESS_KEY}"
        static let secretKey = "{YOUR_SECRET_KEY}"
        static let redirectURI = "{YOUR_REDIRECT_URI}"
    }
    
    private struct OAuthTokenResponseBody: Decodable {
        let accessToken: String
        let tokenType: String
        let scope: String
        let createdAt: Int
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case scope
            case createdAt = "created_at"
        }
    }
    
    enum AuthError: Error {
        case invalidRequest
        case invalidResponse
        case noData
        case requestCancelled
        case tokenDecodingFailed
        case unauthorized
        case forbidden
        case notFound
        case serverError
        case unexpectedStatusCode(Int)
    }
}
