//
//  SettingsView.swift
//  WaveFinder
//
//  Created by snow on 4/27/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var mode
    @AppStorage("minHertz") var minHertz: Double = defaultMinHertz
    @AppStorage("maxHertz") var maxHertz: Double = defaultMaxHertz
    @AppStorage("defaultHertz") var defaultHertz: Double = defaultDefaultHertz
    
    @AppStorage("defaultToPreviousValue") var defaultToPreviousValue: Bool = true
    @AppStorage("verticalMotionBehavior") private var verticalMotionBehavior: VerticalMotionBehavior = defaultVerticalMotionBehavior
    @AppStorage("invertVolume") private var invertVolume: Bool = defaultInvertVolume
    @AppStorage("stopPlaybackWhenReleaed") private var stopPlaybackWhenReleaed: Bool = defaultStopPlaybackWhenReleased
    @AppStorage("showPlayPauseButton") private var showPlayPauseButton: Bool = defaultShowPlayPauseButton
    @AppStorage("playButtonSticky") private var playButtonSticky: Bool = defaultPlayButtonSticky
    
    @State private var localMinHertz: Double
    @State private var localMaxHertz: Double
    @State private var localDefaultHertz: Double
    @State private var errorMessage: String? = nil
    
    
    init() {
        let storedMin = UserDefaults.standard.object(forKey: "minHertz") as? Double ?? defaultMinHertz
        let storedMax = UserDefaults.standard.object(forKey: "maxHertz") as? Double ?? defaultMaxHertz
        let storedDefault = UserDefaults.standard.object(forKey: "defaultHertz") as? Double ?? defaultDefaultHertz
        
        _localMinHertz = State(initialValue: storedMin == 0 ? defaultMinHertz : storedMin)
        _localMaxHertz = State(initialValue: storedMax == 0 ? defaultMaxHertz : storedMax)
        _localDefaultHertz = State(initialValue: storedDefault == 0 ? defaultDefaultHertz : storedDefault)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Min Herts")) {
                        TextField("Min Hertz", value: $localMinHertz, format: .number)
                            .onSubmit {
                                validateAndSave()
                            }
                    }
                    Section(header: Text("Max Herts")) {
                        TextField("Max Hertz", value: $localMaxHertz, format: .number)
                            .onSubmit {
                                validateAndSave()
                            }
                    }
                    Section(header: Text("Default Herts")) {
                        Toggle(isOn: $defaultToPreviousValue) {
                            Text("Remember previous value")
                        }
                        if !defaultToPreviousValue {
                            TextField("Default Hertz", value: $localDefaultHertz, format: .number)
                                .onSubmit {
                                    validateAndSaveDefault()
                                }
                        }
                    }
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    Section(header: Text("Slider behavior")) {
                        Picker("Vertical motion affects",
                               selection: $verticalMotionBehavior) {
                            ForEach(
                                VerticalMotionBehavior.allCases
                            ) { behavior in
                                Text(behavior.rawValue.capitalized)
                                    .tag(behavior)
                            }
                        }
                               .pickerStyle(.segmented)
                        
                        if verticalMotionBehavior == .volume {
                            Toggle(isOn: $invertVolume) {
                                Text("Start at minimum volume")
                            }
                        }
                    }
                    Section(header: Text("Playback")) {
                        Toggle(isOn: $stopPlaybackWhenReleaed) {
                            Text("Stop playback when releasing slider")
                        }
                        .onChange(of: stopPlaybackWhenReleaed) { _, _ in
                            if !stopPlaybackWhenReleaed && !showPlayPauseButton {
                                showPlayPauseButton = true
                            }
                        }
                        Toggle(isOn: $showPlayPauseButton) {
                            Text("Show play/pause button")
                        }
                        .disabled(!stopPlaybackWhenReleaed)
                        if showPlayPauseButton {
                            Toggle(isOn: $playButtonSticky) {
                                Text("Play button is sticky")
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        mode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func validateAndSave() {
        if localMinHertz >= localMaxHertz {
            errorMessage = "Invalid range: Min must be less than Max"
        } else {
            errorMessage = nil
            minHertz = localMinHertz
            maxHertz = localMaxHertz
        }
    }
    
    private func validateAndSaveDefault() {
        if localDefaultHertz < localMinHertz || localDefaultHertz > localMaxHertz {
            errorMessage = "Default must be between Min and Max"
        } else {
            errorMessage = nil
            defaultHertz = localDefaultHertz
        }
    }
}

#Preview {
    SettingsView()
}
