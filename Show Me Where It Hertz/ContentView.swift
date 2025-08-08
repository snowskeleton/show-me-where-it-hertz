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
    @State private var frequency: Double = defaultDefaultHertz
    @State private var audioEngine: AVAudioEngine?
    @State private var oscillatorNode: AVAudioSourceNode?
    @State private var showingSettings = false
    @State private var volumeAdjustment: Float = 0.8
    @State private var isAdjusting: Bool = false
    @State private var toneIsPlaying: Bool = false
    @State private var phase: Double = 0.0
    
    @AppStorage("minHertz") var minPitch: Double = defaultMinHertz
    @AppStorage("maxHertz") var maxPitch: Double = defaultMaxHertz
    @AppStorage("defaultHertz") var defaultPitch: Double = defaultDefaultHertz
    @AppStorage("verticalMotionBehavior") private var verticalMotionBehavior: VerticalMotionBehavior = defaultVerticalMotionBehavior
    @AppStorage("invertVolume") private var invertVolume: Bool = defaultInvertVolume
    @AppStorage("stopPlaybackWhenReleaed") private var stopPlaybackWhenReleaed: Bool = defaultStopPlaybackWhenReleased
    @AppStorage("showPlayPauseButton") private var showPlayPauseButton: Bool = defaultShowPlayPauseButton
    @AppStorage("playButtonSticky") private var playButtonSticky: Bool = defaultPlayButtonSticky
    
    var relativeVolumeAdjustment: Float {
        invertVolume ? 1.0 - volumeAdjustment : volumeAdjustment
    }
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Text("\(Int(frequency)) Hz")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    GeometryReader { geometry in
                        ZStack {
                            Rectangle()
                                .fill(Color.accentColor.opacity(0.1))
                                .cornerRadius(10)
                            
                            WaveformShape(
                                amplitude: CGFloat(relativeVolumeAdjustment) * geometry.size.height / 2,
                                frequency: frequency / 1000,
                                phase: phase
                            )
                            .stroke(Color.accentColor.opacity(toneIsPlaying ? 0.5 : 0.25), lineWidth: 2)
                            .frame(height: geometry.size.height)
                            .onAppear {
                                Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
                                    if toneIsPlaying {
                                        let relative = frequency / minPitch
                                        let speed    = log2(1 + relative) * 0.125
                                        phase += speed                                    }
                                }
                            }
                            
                            HStack {
                                Text(Int(minPitch).description)
                                FineScrubbingSliderView(
                                    value: Binding(
                                        get: { log10(Float(frequency)) },
                                        set: { frequency = pow(10.0, Double($0)) }
                                    ),
                                    range: log10(Float(minPitch))...log10(Float(maxPitch)),
                                    verticalMotionBehavior: verticalMotionBehavior,
                                    volume: $volumeAdjustment,
                                    volumeScrubbingResolution: geometry.size.height / 2,
                                    isAdjusting: $isAdjusting
                                )
                                .id("\(minPitch)-\(maxPitch), \(verticalMotionBehavior)") // Force recreation when range changes
                                .padding()
                                .onChange(of: isAdjusting) { _ in
                                    if isAdjusting {
                                        startTone()
                                    } else {
                                        if stopPlaybackWhenReleaed {
                                            stopTone()
                                        }
                                    }
                                }
                                Text(Int(maxPitch).description)
                            }
                        }
                    }
                    Spacer()
                }
                
                if showPlayPauseButton || !stopPlaybackWhenReleaed {
                    HStack {
                        Button(action: {
                        }) {
                            if !playButtonSticky || !toneIsPlaying {
                                Image(systemName: "play.fill")
                                    .font(.title)
                            } else {
                                Image(systemName: "pause.fill")
                                    .font(.title)
                            }
                        }
                        .padding()
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    print("pressed")
                                    if !toneIsPlaying {
                                        startTone()
                                    } else if playButtonSticky && toneIsPlaying {
                                        print("stop tone")
                                        stopTone()
                                    }
                                }
                                .onEnded { _ in
                                    print("released")
                                    if !playButtonSticky {
                                        stopTone()
                                    }
                                }
                        )
                    }
                }
            }
            .padding()
            .onAppear {
                frequency = defaultPitch
            }
            .onChange(of: minPitch) { _ in
                frequency = min(max(frequency, minPitch), maxPitch)
            }
            .onChange(of: maxPitch) { _ in
                frequency = min(max(frequency, minPitch), maxPitch)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }
    
    func setupAudioEngine() {
        let engine = AVAudioEngine()
        let sampleRate = 44100.0
        var theta = 0.0
        
        let sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            for frame in 0..<Int(frameCount) {
                let theta_increment = 2.0 * Double.pi * self.frequency / sampleRate
                let sampleVal = Float(sin(theta)) * relativeVolumeAdjustment
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
        
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1))
        self.audioEngine = engine
        self.oscillatorNode = sourceNode
    }
    
    func startTone() {
        toneIsPlaying = true
        overrideMudeSwitch()
        
        if audioEngine == nil {
            setupAudioEngine()
        }
        
        do {
            try audioEngine?.start()
        } catch {
            print("Failed to start engine: \(error)")
        }
    }
    
    func stopTone() {
        toneIsPlaying = false
        audioEngine?.stop()
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
