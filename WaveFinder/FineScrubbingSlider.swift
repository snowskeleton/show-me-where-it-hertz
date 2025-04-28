//
//  FineScrubbingSlider.swift
//  WaveFinder
//
//  Created by snow on 4/26/25.
//

import UIKit
import SwiftUI

class FineScrubbingSlider: UISlider {
    private var initialTouchPoint: CGPoint?
    private var lastTouchPoint: CGPoint?
    
    // How much slower scrubbing gets depending on vertical distance
    private var scrubbingSpeed: CGFloat = 1.0
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        self.becomeFirstResponder()
        let point = touch.location(in: self)
        initialTouchPoint = point
        lastTouchPoint = point
        scrubbingSpeed = 1.0
        return super.beginTracking(touch, with: event)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.becomeFirstResponder() // Claim the touch immediately
        super.touchesBegan(touches, with: event)
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        guard let lastTouchPoint = lastTouchPoint else { return super.continueTracking(touch, with: event) }
        
        let currentPoint = touch.location(in: self)
        let verticalDistance = abs(currentPoint.y - (initialTouchPoint?.y ?? currentPoint.y))
        
        let normalizedDistance = min(max(verticalDistance / 100, 0), 1) // normalize between 0 and 1 over 100 points
        scrubbingSpeed = 1.5 - 1.4 * normalizedDistance // starts at 1.0, slows down to 0.1
        
        let deltaX = currentPoint.x - lastTouchPoint.x
        let percentChange = deltaX / bounds.width * CGFloat(maximumValue - minimumValue)
        
        let newValue = value + Float(percentChange * scrubbingSpeed)
        self.value = min(max(newValue, minimumValue), maximumValue)
        
        self.lastTouchPoint = currentPoint
        sendActions(for: .valueChanged)
        
        return true
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}

struct FineScrubbingSliderView: UIViewRepresentable {
    @Binding var value: Float
    var range: ClosedRange<Float>
    
    func makeUIView(context: Context) -> FineScrubbingSlider {
        let slider = FineScrubbingSlider()
        slider.minimumValue = range.lowerBound
        slider.maximumValue = range.upperBound
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
        }
    }
}

