//
//  ContentView.swift
//  WaveFinder
//
//  Created by snow on 4/26/25.
//

import SwiftUI
import AVFoundation
import AVKit

struct ContentView: View {
    @State private var frequency: Double = 1000.0
    @State private var audioEngine: AVAudioEngine?
    @State private var oscillatorNode: AVAudioSourceNode?
    
    let minPitch: Double = 500
    let maxPitch: Double = 20000
    
    
    var body: some View {
        VStack {
            VStack {
                Text("Frequency: \(Int(frequency)) Hz")
                
                ZStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.1)) // Light blue highlight
                        .cornerRadius(10)
                    
                    FineScrubbingSliderView(value: Binding(
                        get: { Float(frequency) },
                        set: { frequency = Double($0) }
                    ), range: Float(minPitch)...Float(maxPitch))
                    .padding()
                    .onChange(of: frequency) { _, _ in
                        startTone()
                    }
                }
                Spacer()
            }
            
            HStack {
                Button(action: {
                    startTone()
                }) {
                    Image(systemName: "play.fill")
                        .font(.title)
                }
                .padding()
                
                Button(action: {
                    stopTone()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.title)
                }
                .padding()
            }
        }
        .padding()
    }
    
    func startTone() {
        overrideMudeSwitch()
        
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
    
    fileprivate func overrideMudeSwitch() {
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
    }
}

//#Preview {
//    ContentView()
//}
