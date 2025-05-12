//
//  WaveformShape.swift
//  Show Me Where It Hertz
//
//  Created by snow on 5/12/25.
//


import SwiftUI
import AVFoundation
import AVKit

struct WaveformShape: Shape {
    var amplitude: CGFloat
    var frequency: Double
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let width = rect.width
        let samples = Int(width)
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        for x in 0..<samples {
            let progress = Double(x) / Double(samples)
            let angle = 2 * .pi * frequency * progress + phase
            let y = midY + sin(angle) * amplitude
            path.addLine(to: CGPoint(x: CGFloat(x), y: y))
        }
        
        return path
    }
}
