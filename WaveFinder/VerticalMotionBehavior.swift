//
//  VerticalMotionBehavior.swift
//  WaveFinder
//
//  Created by snow on 4/27/25.
//


import SwiftUI

enum VerticalMotionBehavior: String, CaseIterable, Identifiable, Codable {
    case sensitivity
    case volume
    
    var id: String { self.rawValue }
}
