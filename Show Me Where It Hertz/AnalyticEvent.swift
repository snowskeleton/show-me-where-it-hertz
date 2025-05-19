//
//  AnalyticEvent.swift
//  Show Me Where It Hertz
//
//  Created by snow on 5/19/25.
//


import Foundation
import Aptabase

enum AnalyticEvent: String {
    case appLaunch
    case appLaunchFirstTime


    case analyticsDisabled
    case analyticsEnabled
    
    case openedAnalyticsView
    case openedDeveloperMenu
}
