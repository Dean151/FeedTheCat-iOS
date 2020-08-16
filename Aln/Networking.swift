//
//  Networking.swift
//  Aln
//
//  Created by Thomas Durand on 11/02/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import AuthenticationServices
import Combine
import Foundation
import os.log

// MARK: - Generic

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

public final class Networking {
    let decoder: JSONDecoder
    let session: URLSession
    let baseUrl: URL

    var token: String?

    public init(baseUrl: URL) {
        self.decoder = JSONDecoder()
        self.session = URLSession(configuration: .default)
        self.baseUrl = baseUrl

        // Needs fractional seconds (2018-12-28T16:28:13.000Z)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(formatter)
    }

    func request(_ subpath: String, method: HTTPMethod, skipCache: Bool = false) -> URLRequest {
        var request = URLRequest(url: baseUrl.appendingPathComponent(subpath))
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if method != .get, let token = token {
            request.addValue(token, forHTTPHeaderField: "x-csrf-token")
        }
        return request
    }

    func request<T: Encodable>(_ subpath: String, method: HTTPMethod, skipCache: Bool = false, body: T) -> URLRequest {
        var request = self.request(subpath, method: method)
        if skipCache {
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        let encoder = JSONEncoder()
        do {
            request.httpBody = try encoder.encode(body)
        } catch {}
        return request
    }

    func performRequest<R: Decodable>(_ subpath: String, method: HTTPMethod, skipCache: Bool = false) -> AnyPublisher<R, Error> {
        return session.dataTaskPublisher(for: request(subpath, method: method, skipCache: skipCache))
            .map { $0.data }
            .decode(type: R.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    func performRequest<T: Encodable, R: Decodable>(_ subpath: String, method: HTTPMethod, skipCache: Bool = false, body: T) -> AnyPublisher<R, Error> {
        return session.dataTaskPublisher(for: request(subpath, method: method, skipCache: skipCache, body: body))
            .map { $0.data }
            .decode(type: R.self, decoder: decoder)
            .tryCatch({ (error) throws -> AnyPublisher<R, Never> in
                os_log("Networking error: %{PUBLIC}@", type: .error, error.localizedDescription)
                // Rethrow
                throw error
            })
            .eraseToAnyPublisher()
    }

    public struct StatusResponse: Codable, Identifiable {
        public let success: Bool
        public var id: Bool {
            return success
        }
        static let failure = StatusResponse(success: false)
    }
}

// MARK: - Login / Logout

extension Networking {
    public struct LogUserResponse: Codable {
        public let success: Bool
        public let user: User?
        public let token: String?

        public static let loginFailed = LogUserResponse(success: false, user: nil, token: nil)
    }
    public func logUser(credentials: ASAuthorizationAppleIDCredential) -> AnyPublisher<LogUserResponse, Error> {
        struct LogUserData: Codable {
            let appleId: String
            let email: String?
            let authorizationCode: Data?
            let identityToken: Data?
        }

        let body = LogUserData(
            appleId: credentials.user,
            email: credentials.email,
            authorizationCode: credentials.authorizationCode,
            identityToken: credentials.identityToken
        )
        return performRequest("api/user/login", method: .post, body: body)
    }

    public struct CheckSessionResponse: Codable {
        public let loggedIn: Bool
        public let user: User?
        public let token: String?

        public static let notLoggedIn = CheckSessionResponse(loggedIn: false, user: nil, token: nil)
    }
    public func checkSession(appleId: String) -> AnyPublisher<CheckSessionResponse, Error> {
        struct CheckUserData: Codable {
            let appleId: String
        }
        let body = CheckUserData(appleId: appleId)
        return performRequest("api/user/check", method: .post, body: body)
    }

    public func logoutUser() -> AnyPublisher<StatusResponse, Error> {
        performRequest("api/user/logout", method: .post)
    }
}

// MARK: - Feeder

extension Networking {
    public func getFeederStatus(id: Int) -> AnyPublisher<FeederState, Error> {
        performRequest("/api/feeder/\(id)", method: .get, skipCache: true)
    }

    public func setFeederName(id: Int, name: String) -> AnyPublisher<StatusResponse, Error> {
        struct FeederNameData: Codable {
            let name: String
        }
        let body = FeederNameData(name: name)
        return performRequest("/api/feeder/\(id)", method: .put, body: body)
    }

    public func setFeederDefaultAmount(id: Int, amount: Amount) -> AnyPublisher<StatusResponse, Error> {
        struct DefaultAmountData: Codable {
            let quantity: Amount
        }
        let body = DefaultAmountData(quantity: amount)
        return performRequest("/api/feeder/\(id)/quantity", method: .put, body: body)
    }
}

// MARK: - Meal & Plans

extension Networking {
    public func feedNow(id: Int, amount: Amount) -> AnyPublisher<StatusResponse, Error> {
        struct FeedNowData: Codable {
            let quantity: Amount
        }
        let body = FeedNowData(quantity: amount)
        return performRequest("/api/feeder/\(id)/feed", method: .post, body: body)
    }

    public func getFeederPlanning(id: Int) -> AnyPublisher<ScheduledFeedingPlan, Error> {
        performRequest("/api/feeder/\(id)/planning", method: .get)
    }

    public func setFeederPlanning(feeder: Feeder, plan: ScheduledFeedingPlan) -> AnyPublisher<StatusResponse, Error> {
        return performRequest("/api/feeder/\(feeder.id)/planning", method: .put, body: plan)
    }
}

extension HTTPCookieStorage {
    func deleteAllCookies() {
        for cookie in self.cookies ?? [] {
            self.deleteCookie(cookie)
        }
    }
}
