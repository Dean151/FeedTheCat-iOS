//
//  Persistent.swift
//  Aln
//
//  Created by Thomas DURAND on 12/08/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import KeychainAccess
import os.log

enum Persistent {
    @KeychainItem("appleId", service: "fr.thomasdurand.aln")
    static var appleId: String?

    @KeychainItem("session", service: "fr.thomasdurand.aln")
    static var session: User.Session?
}

@propertyWrapper
struct UserDefaultItem<T> {
    let key: String
    let store: UserDefaults

    init(_ key: String, store: UserDefaults = UserDefaults.standard) {
        self.store = store
        self.key = key
    }

    var wrappedValue: T? {
        get {
            return store.object(forKey: key) as? T
        }
        set {
            if let newValue = newValue {
                store.set(newValue, forKey: key)
            } else {
                store.removeObject(forKey: key)
            }
        }
    }
}

@propertyWrapper
struct KeychainItem<T: Codable> where T: Equatable {
    let keychain: Keychain
    let key: String

    enum Errors: Error {
        case noData
    }

    init(_ key: String, service: String) {
        self.key = key
        self.keychain = Keychain(service: service).accessibility(.afterFirstUnlockThisDeviceOnly)
    }

    var wrappedValue: T? {
        get {
            guard let data = keychain[data: key] else {
                os_log("No data for key `%{PUBLIC}@` from keychain", type: .info, key)
                return nil
            }
            do {
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
                return unarchiver.decodeDecodable(T.self, forKey: "data")
            } catch {
                os_log("Un-decodable data for key `%{PUBLIC}@` from keychain: %{PUBLIC}@", type: .info, key, error.localizedDescription)
                return nil
            }
        }
        set {
            do {
                let archiver = NSKeyedArchiver(requiringSecureCoding: true)
                try archiver.encodeEncodable(newValue, forKey: "data")
                keychain[data: key] = archiver.encodedData
            } catch {
                os_log("Could not encode `%{PUBLIC}@` to keychain: %{PUBLIC}@", type: .error, key, error.localizedDescription)
            }
        }
    }
}
