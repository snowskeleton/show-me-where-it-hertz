//
//  FineScrubbingSlider.swift
//  WaveFinder
//
//  Created by snow on 4/26/25.
//

import UIKit
import SwiftUI
import MediaPlayer

class FineScrubbingSlider: UISlider {
    private var initialTouchPoint: CGPoint?
    private var lastTouchPoint: CGPoint?
    
    private var scrubbingSpeed: CGFloat = 1.0
    
    var verticalMotionBehavior: VerticalMotionBehavior = .sensitivity
    var volume: Float = 1.0
    var volumeScrubbingResolution: CGFloat = 250.0
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        self.becomeFirstResponder()
        let point = touch.location(in: self)
        initialTouchPoint = point
        lastTouchPoint = point
        scrubbingSpeed = 1.0
        return super.beginTracking(touch, with: event)
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard let lastTouchPoint = lastTouchPoint else { return super.continueTracking(touch, with: event) }
        
        let currentPoint = touch.location(in: self)
        let deltaX = currentPoint.x - lastTouchPoint.x
        let percentChange = deltaX / bounds.width * CGFloat(maximumValue - minimumValue)
        let verticalDistance = abs(currentPoint.y - (initialTouchPoint?.y ?? currentPoint.y))
        
        switch verticalMotionBehavior {
        case .sensitivity:
            let normalizedDistance = min(max(verticalDistance / sensitivityScrubbingResolution, 0), 1)
            scrubbingSpeed = scrubbingMaxSpeed - (scrubbingMaxSpeed - 0.1) * normalizedDistance
            let newValue = value + Float(percentChange * scrubbingSpeed)
            self.value = min(max(newValue, minimumValue), maximumValue)
            
        case .volume:
            let normalizedDistance = min(max(verticalDistance / volumeScrubbingResolution, 0), 1)
            let volumeLevel = Float(1.0 - normalizedDistance)
            self.volume = Float(volumeLevel)
            
            let newValue = value + Float(percentChange)
            self.value = min(max(newValue, minimumValue), maximumValue)
        }
        self.lastTouchPoint = currentPoint
        sendActions(for: .valueChanged)
        
        return true
    }
}

struct FineScrubbingSliderView: UIViewRepresentable {
    @Binding var value: Float
    var range: ClosedRange<Float>
    var verticalMotionBehavior: VerticalMotionBehavior = .sensitivity
    @Binding var volume: Float
    var volumeScrubbingResolution: CGFloat
    @Binding var isAdjusting: Bool
    
    func makeUIView(context: Context) -> FineScrubbingSlider {
        let slider = FineScrubbingSlider()
        slider.minimumValue = range.lowerBound
        slider.maximumValue = range.upperBound
        slider.verticalMotionBehavior = verticalMotionBehavior
        slider.volumeScrubbingResolution = volumeScrubbingResolution
        slider.addTarget(context.coordinator, action: #selector(Coordinator.valueChanged(_:)), for: .valueChanged)
        return slider
    }
    
    func updateUIView(_ uiView: FineScrubbingSlider, context: Context) {
        uiView.value = value
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: FineScrubbingSliderView
        
        init(_ parent: FineScrubbingSliderView) {
            self.parent = parent
        }
        
        @objc func valueChanged(_ sender: FineScrubbingSlider) {
            parent.value = sender.value
            if parent.verticalMotionBehavior == .volume {
                parent.volume = sender.volume
            }
        }
    }
}
