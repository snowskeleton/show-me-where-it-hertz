//
//  Analytics.swift
//  Show Me Where It Hertz
//
//  Created by snow on 5/19/25.
//

import Foundation
import Aptabase

class Analytics {
    static private func privateTrack(_ event: AnalyticEvent, with options: [String: Any]?) {
        #if DEBUG
        let disabled = true
        #else
        let disabled = UserDefaults.standard.bool(forKey: "isAnalyticsDisabled")
        #endif
        if disabled {
            return
        }
        
        let expiryTimestamp = UserDefaults.standard.double(forKey: "optInTrackingIdentifierExpiry")
        let expiryDate = Date(timeIntervalSince1970: expiryTimestamp)
        
        if Date() > expiryDate {
            UserDefaults.standard.set("", forKey: "optInTrackingIdentifier")
            UserDefaults.standard.set(0, forKey: "optInTrackingIdentifierExpiry")
        }
        
        var modifiedOptions = options ?? [:]
        if let id = UserDefaults.standard.string(forKey: "optInTrackingIdentifier"), !id.isEmpty {
            modifiedOptions["trackingIdentifier"] = id
        }
        
        if modifiedOptions.isEmpty {
            Aptabase.shared.trackEvent(event.rawValue)
        } else {
            Aptabase.shared.trackEvent(event.rawValue, with: modifiedOptions)
        }
    }
    
    static func track(_ event: AnalyticEvent ) {
        Analytics.privateTrack(event, with: nil)
    }
    static func track(_ event: AnalyticEvent, with options: [String: Any]) {
        Analytics.privateTrack(event, with: options)
    }
}
