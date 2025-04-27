//
//  WaveFinderView.swift
//  WaveFinder
//
//  Created by snow on 4/26/25.
//
import SwiftUI
import AVFoundation
import AVKit



struct WaveFinderView: View {
    @State private var frequency: Double = 1000.0
    @State private var step: Double = 100.0
    @State private var audioEngine: AVAudioEngine?
    @State private var oscillatorNode: AVAudioSourceNode?
    
    let stableMinPitch: Double = 500
    let stableMaxPitch: Double = 20000
    @State var minPitch: Double = 500
    @State var maxPitch: Double = 20000
    
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Frequency: \(Int(frequency)) Hz")
            
            
            Slider(value: $frequency, in: minPitch...maxPitch, step: step) {
                Text("Frequency")
            }
            minimumValueLabel: {
                Text(minPitch.description)
            } maximumValueLabel: {
                Text(maxPitch.description)
            }
            .onChange(of: frequency) { _, _ in
                startTone()
            }
            
            VStack {
                Text("Resolution")
                HStack {
                    Button(action: {
                        step = 1.0
                        setPitchRange()
                    }) {
                        Text("1")
                            .font(.title)
                            .padding()
                    }
                    
                    Button(action: {
                        step = 20.0
                        setPitchRange()
                    }) {
                        Text("20")
                            .font(.title)
                            .padding()
                    }
                    
                    Button(action: {
                        step = 100.0
                        setPitchRange()
                    }) {
                        Text("100")
                            .font(.title)
                            .padding()
                    }
                }
            }
            
            Button(action: {
                startTone()
            }) {
                Text("Start Tone")
                    .font(.title)
                    .padding()
            }
            
            Button(action: {
                stopTone()
            }) {
                Text("Stop Tone")
                    .font(.title)
                    .padding()
            }
        }
        .padding()
    }
    
    private func setPitchRange() {
        let stepFactor = step * 200
        minPitch = max(frequency - stepFactor, stableMinPitch)
        maxPitch = min(frequency + stepFactor, stableMaxPitch)
    }
    
    func startTone() {
        // disable mute switch
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            //print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                //print("AVAudioSession is Active")
            } catch _ as NSError {
                //print(error.localizedDescription)
            }
        } catch _ as NSError {
            //print(error.localizedDescription)
        }
        
        guard audioEngine == nil else { return }
        
        let engine = AVAudioEngine()
        let sampleRate = 44100.0
        var theta = 0.0
        
        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let theta_increment = 2.0 * Double.pi * self.frequency / sampleRate
                let sampleVal = Float(sin(theta))
                theta += theta_increment
                if theta > 2.0 * Double.pi {
                    theta -= 2.0 * Double.pi
                }
                for buffer in ablPointer {
                    buffer.mData?.storeBytes(of: sampleVal, toByteOffset: frame * MemoryLayout<Float>.size, as: Float.self)
                }
            }
            return noErr
        }
        
        stopTone()  // Stop any existing tone first
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        
        do {
            try engine.start()
            self.audioEngine = engine
            self.oscillatorNode = sourceNode
        } catch {
            print("Failed to start engine: \(error)")
        }
    }
    
    func stopTone() {
        audioEngine?.stop()
        audioEngine = nil
        oscillatorNode = nil
    }
}
