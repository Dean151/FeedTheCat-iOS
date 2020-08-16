//
//  AppState.swift
//  Aln
//
//  Created by Thomas DURAND on 11/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import AuthenticationServices
import Combine
import Network
import SwiftUI
import os.log

public class AppState: NSObject, ObservableObject {

    public static let standard: AppState = .init()

    // Helpers for previews
    public static let loading: AppState = .init(state: .loading)
    public static let noInternet: AppState = .init(state: .noInternetConnexion)
    public static let notLoggedIn: AppState = .init(state: .notLoggedIn)

    private let monitor: NWPathMonitor
    private let networking: Networking
    var cancellables = Set<AnyCancellable>()

    @Published public var state: LoginState

    private init(state: LoginState? = nil) {
        self.state = state ?? .loading
        self.monitor = NWPathMonitor()
        self.networking = Networking(baseUrl: URL(string: "https://alnpetdev.thomasdurand.fr")!)
        super.init()
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status != .satisfied {
                self?.state = .noInternetConnexion
            } else if case .noInternetConnexion = self?.state {
                self?.state = .loading
            }
        }
        monitor.start(queue: .main)
    }
}

// MARK: - Login

public enum LoginState {
    case loading
    case noInternetConnexion
    case notLoggedIn
    case loggedIn(user: User)
}

extension AppState: ASAuthorizationControllerDelegate {
    public func attemptLogin(with credential: ASAuthorizationAppleIDCredential, onError errorHandler: (() -> Void)? = nil) {
        os_log("Sign-in with apple succeeded with appleid: %{PRIVATE}@", type: .debug, credential.user)
        // Sign back in or create account
        networking.logUser(credentials: credential)
            .replaceError(with: .loginFailed)
            .sink { result in
                guard let user = result.user, let token = result.token, result.success else {
                    os_log("Could not log-in", type: .info)
                    DispatchQueue.main.async {
                        self.state = .notLoggedIn
                        errorHandler?()
                    }
                    return
                }

                // Save the appleid
                Persistent.appleId = credential.user

                // Save the session cookie
                if let cookie = HTTPCookieStorage.shared.cookies?.first(where: { $0.domain == self.networking.baseUrl.host && $0.name.hasSuffix(".sid") }) {
                    Persistent.session = User.Session(cookie: cookie)
                }

                os_log("Now logged in as %{PRIVATE}@", type: .debug, user.email ?? "no email")
                DispatchQueue.main.async {
                    self.networking.token = token
                    self.state = .loggedIn(user: user)
                }
            }
            .store(in: &cancellables)
    }

    public func restoreSession() {
        guard let appleId = Persistent.appleId else {
            os_log("No appleId in persistent store", type: .info)
            self.state = .notLoggedIn
            return
        }
        os_log("Will check state for apple id %{PRIVATE}@", type: .info, appleId)
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: appleId) { (state, error) in
            switch state {
            case .authorized:
                // Restore session cookie if any
                if let cookie = Persistent.session?.cookie {
                    HTTPCookieStorage.shared.setCookie(cookie)
                }
                os_log("Will check state with our own back-end", type: .info)
                self.networking.checkSession(appleId: appleId)
                    .replaceError(with: .notLoggedIn)
                    .sink { (status) in
                        if let user = status.user, let token = status.token, status.loggedIn {
                            os_log("Now logged in as %{PRIVATE}@", type: .debug, user.email ?? "no email")
                            DispatchQueue.main.async {
                                self.networking.token = token
                                self.state = .loggedIn(user: user)
                            }
                        } else {
                            // Session is not anymore valid
                            Persistent.session = nil
                            HTTPCookieStorage.shared.deleteAllCookies()
                            // Reconnect
                            DispatchQueue.main.async {
                                let request = ASAuthorizationAppleIDProvider().createRequest()
                                os_log("Sign-in with apple requested", type: .debug)
                                let controller = ASAuthorizationController(authorizationRequests: [request])
                                controller.delegate = self
                                controller.performRequests()
                            }
                        }
                    }
                    .store(in: &self.cancellables)
                break
            default:
                // Erase the session, present login
                Persistent.appleId = nil
                Persistent.session = nil
                HTTPCookieStorage.shared.deleteAllCookies()
                self.networking.token = nil
                self.state = .notLoggedIn
            }
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let credential as ASAuthorizationAppleIDCredential:
            attemptLogin(with: credential)
        default:
            os_log("Could not log-in", type: .fault)
            DispatchQueue.main.async {
                self.state = .notLoggedIn
            }
        }
    }

    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Go back to not logged in state
        os_log("An error occurred while logging in: %{PUBLIC}@", type: .error, error.localizedDescription)
        DispatchQueue.main.async {
            self.state = .notLoggedIn
        }
    }
}

// MARK: - Feeder

public enum FeederState: Equatable {
    case unknown
    case available
    case notAvailable(lastReachDate: Date?)

    public var isReachable: Bool {
        switch self {
        case .available:
            return true
        default:
            return false
        }
    }

    public static func == (lhs: FeederState, rhs: FeederState) -> Bool {
        switch lhs {
        case .available:
            if case .available = rhs {
                return true
            } else {
                return false
            }
        case .unknown:
            if case .unknown = rhs {
                return true
            } else {
                return false
            }
        case .notAvailable(lastReachDate: let lhsDate):
            if case .notAvailable(lastReachDate: let rhsDate) = rhs {
                return lhsDate == rhsDate
            } else {
                return false
            }
        }
    }
}
extension FeederState: Decodable {
    enum CodingKeys: String, CodingKey {
        case lastResponded
        case isAvailable
    }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let available: Bool = try values.decode(Bool.self, forKey: .isAvailable)
        self = available ? .available : .notAvailable(lastReachDate: nil)
    }
}
extension FeederState: CVarArg {
    public var _cVarArgEncoding: [Int] {
        switch self {
        case .unknown:
            return "unknown"._cVarArgEncoding
        case .available:
            return "available"._cVarArgEncoding
        case .notAvailable:
            return "not available"._cVarArgEncoding
        }
    }
}

extension AppState {
    public func checkFeederStatus(feeder: Feeder, updated: @escaping (FeederState) -> Void) {
        networking.getFeederStatus(id: feeder.id)
            .replaceError(with: .unknown)
            .sink { updated($0) }
            .store(in: &cancellables)
    }

    public func feedNow(feeder: Feeder, quantity: Int, completed: @escaping (Networking.StatusResponse) -> Void) throws {
        networking.feedNow(id: feeder.id, amount: try Amount(value: quantity))
            .replaceError(with: .failure)
            .sink { completed($0) }
            .store(in: &cancellables)
    }
}

// MARK: - Feeder Settings


public class FeederSettingsValues: ObservableObject {
    @Published public var name: String
    @Published public var defaultAmount: Int
    @Published public var planning: Result<ScheduledFeedingPlan, Error>?

    var original: (name: String, defaultAmount: Int)
    var savePlan = false

    public init(feeder: Feeder) {
        name = feeder.name ?? ""
        defaultAmount = feeder.defaultAmount ?? Amount.min
        original = (feeder.name ?? "", feeder.defaultAmount ?? Amount.min)
    }

    public var underlyingPlanning: ScheduledFeedingPlan {
        get {
            if case let .success(plan) = planning {
                return plan
            } else {
                return .empty
            }
        }
        set {
            planning = .success(newValue)
            savePlan = true
        }
    }
}

extension AppState {
    public func loadPlanning(for feeder: Feeder, in values: FeederSettingsValues) {
        networking.getFeederPlanning(id: feeder.id)
            .receive(on: DispatchQueue.main)
            .sink { (completion) in
                if case let .failure(error) = completion {
                    values.planning = .failure(error)
                }
            } receiveValue: { (plan) in
                values.planning = .success(plan)
            }
            .store(in: &cancellables)
    }

    public func saveFeederSettings(_ values: FeederSettingsValues, for feeder: Feeder, completion: @escaping (Bool) -> Void) {
        var publishers: [AnyPublisher<Networking.StatusResponse, Error>] = []
        if values.name != values.original.name {
            publishers.append(
                networking.setFeederName(id: feeder.id, name: values.name)
                    .receive(on: DispatchQueue.main)
                    .map({ value in
                        if value.success {
                            feeder.name = values.name
                        }
                        return value
                    })
                    .eraseToAnyPublisher()
            )
        }
        if values.defaultAmount != values.original.defaultAmount, let amount = try? Amount(value: values.defaultAmount) {
            publishers.append(
                networking.setFeederDefaultAmount(id: feeder.id, amount: amount)
                    .receive(on: DispatchQueue.main)
                    .map({ (value: Networking.StatusResponse) -> Networking.StatusResponse in
                        if value.success {
                            feeder.defaultAmount = values.defaultAmount
                        }
                        return value
                    })
                    .eraseToAnyPublisher()
            )
        }
        if case let .success(planning) = values.planning, values.savePlan {
            publishers.append(networking.setFeederPlanning(feeder: feeder, plan: planning))
        }
        if publishers.isEmpty {
            completion(true)
            return
        }
        Publishers.MergeMany(publishers)
            .collect()
            .sink { (completed) in
                if case .failure = completed {
                    completion(false)
                }
            } receiveValue: { values in
                completion(values.reduce(true, { $0 && $1.success }))
            }
            .store(in: &cancellables)
    }
}
