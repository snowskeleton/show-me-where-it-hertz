//
//  DynamicSlider.swift
//  WaveFinder
//
//  Created by snow on 4/26/25.
//

import SwiftUI

struct TutorialSliderButton: View {
    var knobPadding: CGFloat = 8
    var onComplete: () -> () = { }
    var onDrag: (Double) -> () = { _ in }
    var latchesOn: Bool = true
    var range: ClosedRange<Double>
    var stepSize: Double = 1.0
    @Binding var value: Double  // Add a binding to track the value
    
    @State private var knobXOffset: CGFloat = 0
    @State private var knobWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geom in
            ZStack(alignment: .leading) {
                // TRACK
                Capsule()
                    .fill(.tint.quaternary)
                // KNOB
                Circle()
                    .fill(.tint)
                    .padding(knobPadding)
                    .onGeometryChange(for: CGSize.self, of: { proxy in
                        proxy.size // get the modified view's size
                    }, action: { size in
                        self.knobWidth = size.width
                    })
                    .offset(x: knobXOffset) // Set this BEFORE the gesture
                    .gesture(dragGesture(with: geom))
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
    }
    
    private func dragGesture(with geomProxy: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let geomFrame = geomProxy.frame(in: .local)
                let totalWidth = geomFrame.width
                let totalHeight = geomFrame.height
                
                let newPosition = min(max(value.location.x, 0), totalWidth - knobWidth)
                
                // Calculate the number of steps based on the range and step size
                let totalSteps = (range.upperBound - range.lowerBound) / stepSize
                let segmentWidth = totalWidth / CGFloat(totalSteps)
                
                // Calculate the closest step and update the knob position
                let closestStep = round(newPosition / segmentWidth)
                knobXOffset = closestStep * segmentWidth
                
                // Map the position to the range
                let mappedValue = range.lowerBound + closestStep * stepSize
                self.value = mappedValue // Update the value binding directly
                onDrag(mappedValue)
            }
            .onEnded { _ in
                // Optionally handle snapping or final state
            }
    }
}
