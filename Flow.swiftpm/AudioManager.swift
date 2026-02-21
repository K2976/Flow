import Foundation
import AVFoundation

// MARK: - Audio Manager

@MainActor
@Observable
final class AudioManager {
    
    private var audioEngine: AVAudioEngine?
    private var calmNode: AVAudioPlayerNode?
    private var stressNode: AVAudioPlayerNode?
    private var calmBuffer: AVAudioPCMBuffer?
    private var stressBuffer: AVAudioPCMBuffer?
    
    private(set) var isPlaying: Bool = false
    var isMuted: Bool = false
    
    private let sampleRate: Double = 44100
    private let bufferDuration: Double = 2.0 // 2-second loop
    
    init() {
        setupAudio()
    }
    
    // MARK: - Setup
    
    private func setupAudio() {
        let engine = AVAudioEngine()
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        
        // Create calm tone buffer (~220Hz gentle sine)
        calmBuffer = createToneBuffer(frequency: 220, amplitude: 0.08, format: format)
        
        // Create stress tone buffer (~440Hz with modulation)
        stressBuffer = createToneBuffer(frequency: 440, amplitude: 0.05, format: format, modulation: true)
        
        let calmPlayer = AVAudioPlayerNode()
        let stressPlayer = AVAudioPlayerNode()
        
        engine.attach(calmPlayer)
        engine.attach(stressPlayer)
        
        // Add reverb for spaciousness
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.largeHall)
        reverb.wetDryMix = 60
        engine.attach(reverb)
        
        engine.connect(calmPlayer, to: reverb, format: format)
        engine.connect(stressPlayer, to: reverb, format: format)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        
        self.audioEngine = engine
        self.calmNode = calmPlayer
        self.stressNode = stressPlayer
    }
    
    private func createToneBuffer(frequency: Double, amplitude: Float, format: AVAudioFormat, modulation: Bool = false) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * bufferDuration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData?[0] else { return nil }
        
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample = sin(2.0 * .pi * frequency * t) * Double(amplitude)
            
            if modulation {
                // Add gentle LFO modulation
                let lfo = sin(2.0 * .pi * 3.0 * t) * 0.3
                sample *= (1.0 + lfo)
            }
            
            // Smooth fade at buffer boundaries to prevent clicks
            let fadeLength = 1000
            if i < fadeLength {
                sample *= Double(i) / Double(fadeLength)
            } else if i > Int(frameCount) - fadeLength {
                sample *= Double(Int(frameCount) - i) / Double(fadeLength)
            }
            
            channelData[i] = Float(sample)
        }
        
        return buffer
    }
    
    // MARK: - Playback
    
    func startAmbient() {
        guard !isPlaying, let engine = audioEngine else { return }
        
        do {
            try engine.start()
            
            if let calmNode = calmNode, let buffer = calmBuffer {
                calmNode.scheduleBuffer(buffer, at: nil, options: .loops)
                calmNode.volume = 0.6
                calmNode.play()
            }
            
            if let stressNode = stressNode, let buffer = stressBuffer {
                stressNode.scheduleBuffer(buffer, at: nil, options: .loops)
                stressNode.volume = 0.0
                stressNode.play()
            }
            
            isPlaying = true
        } catch {
            // Silent failure
        }
    }
    
    func stopAmbient() {
        calmNode?.stop()
        stressNode?.stop()
        audioEngine?.stop()
        isPlaying = false
    }
    
    func updateForScore(_ score: Double) {
        guard isPlaying, !isMuted else { return }
        
        let normalizedScore = min(max(score, 0), 100) / 100.0
        
        // Calm fades out as stress rises
        calmNode?.volume = Float(1.0 - normalizedScore * 0.6)
        stressNode?.volume = Float(normalizedScore * 0.7)
    }
    
    func setFocusMode(_ enabled: Bool) {
        if enabled {
            stressNode?.volume = 0
            calmNode?.volume = 0.8
        }
    }
    
    func playEventChime() {
        // Short burst — schedule a brief buffer
        // For simplicity, we just slightly boost calm node momentarily
        guard isPlaying, !isMuted else { return }
        let originalVolume = calmNode?.volume ?? 0.6
        calmNode?.volume = min(originalVolume + 0.3, 1.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.calmNode?.volume = originalVolume
        }
    }
    
    func playCompletionChime() {
        guard !isMuted else { return }
        // Brief gold-tone chime effect
        let originalVolume = calmNode?.volume ?? 0.6
        calmNode?.volume = 1.0
        stressNode?.volume = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.calmNode?.volume = originalVolume
        }
    }
}
