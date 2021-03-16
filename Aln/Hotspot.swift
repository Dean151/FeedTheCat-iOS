//
//  Hotspot.swift
//  Aln
//
//  Created by Thomas DURAND on 10/09/2020.
//  Copyright © 2020 Thomas DURAND. All rights reserved.
//

import Foundation
import Network
import NetworkExtension

enum Hotspot {
    enum Encryption {
        enum WepAlgorithm {
            case ascii
            case hex
        }
        enum WpaAlgorithm {
            case aes
            case tkip
        }

        case none
        case openwep(algorithm: WepAlgorithm, passphrase: String)
        case sharedwep(algorithm: WepAlgorithm, passphrase: String)
        case wpapsk(algorithm: WpaAlgorithm, passphrase: String)
        case wpa2psk(algorithm: WpaAlgorithm, passphrase: String)
    }

    static func updateWifiSettings(ssid: String, encryption: Encryption) {
        let configuration = NEHotspotConfiguration(ssid: "HF-LPT120")
        NEHotspotConfigurationManager.shared.apply(configuration) { error in
            print(error)
        }
    }
}
