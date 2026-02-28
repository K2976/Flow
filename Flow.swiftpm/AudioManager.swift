import Foundation
import AVFoundation

// MARK: - Audio Manager
// True stereo binaural beats: different frequency in each ear creates
// a perceived beat at the difference frequency (e.g. 200Hz L + 240Hz R = 40Hz beat).
// Layered with warm harmonics and shaped brown noise for a full, professional sound.

@MainActor
@Observable
final class AudioManager {
    
    private var calmPlayer: AVAudioPlayer?
    private var stressPlayer: AVAudioPlayer?
    
    private(set) var isPlaying: Bool = false
    var isMuted: Bool = false
    
    private let sampleRate: Double = 44100
    private let bufferDuration: Double = 30.0 // longer loop for seamless feel
    
    // Simple seeded RNG for deterministic noise (no import needed)
    private struct SimpleRNG {
        private var state: UInt64
        init(seed: UInt64) { state = seed }
        
        mutating func next() -> Double {
            // xorshift64
            state ^= state &<< 13
            state ^= state &>> 7
            state ^= state &<< 17
            return Double(state % 1_000_000) / 1_000_000.0 * 2.0 - 1.0
        }
    }
    
    init() {
        setupAudio()
    }
    
    // MARK: - Setup
    
    private func setupAudio() {
        // Calm layer: 10Hz alpha binaural beat (carrier ~432Hz) — smooth, warm
        if let calmData = generateBinauralWAV(
            carrierHz: 432, beatHz: 10,
            toneAmp: 0.18, noiseAmp: 0.015,
            warmth: 0.04
        ) {
            calmPlayer = try? AVAudioPlayer(data: calmData)
            calmPlayer?.numberOfLoops = -1
            calmPlayer?.volume = 0.50
            calmPlayer?.prepareToPlay()
        }
        
        // Stress layer: 40Hz gamma binaural beat (carrier 200Hz) — deep, cinematic
        if let stressData = generateBinauralWAV(
            carrierHz: 200, beatHz: 40,
            toneAmp: 0.22, noiseAmp: 0.035,
            warmth: 0.015
        ) {
            stressPlayer = try? AVAudioPlayer(data: stressData)
            stressPlayer?.numberOfLoops = -1
            stressPlayer?.volume = 0.0
            stressPlayer?.prepareToPlay()
        }
    }
    
    // MARK: - True Stereo Binaural Beat Generator
    
    /// Generates stereo WAV: left ear = carrier Hz, right ear = (carrier + beat) Hz.
    /// The brain perceives the difference as the binaural beat frequency.
    /// Adds subtle harmonics for warmth and shaped brown noise for fullness.
    private func generateBinauralWAV(
        carrierHz: Double,
        beatHz: Double,
        toneAmp: Double,
        noiseAmp: Double,
        warmth: Double
    ) -> Data? {
        let numChannels: UInt16 = 2  // STEREO — essential for binaural
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = Int(bitsPerSample / 8)
        
        // Phase-aligned frame count for seamless looping
        // Find a duration that's an exact multiple of both carrier periods
        let lcmPeriod = 1.0 / gcd(carrierHz, carrierHz + beatHz)
        let loopCycles = max(1, Int(bufferDuration / lcmPeriod))
        let exactDuration = Double(loopCycles) * lcmPeriod
        let frameCount = Int(exactDuration * sampleRate)
        
        let dataSize = frameCount * Int(numChannels) * bytesPerSample
        
        var data = Data()
        data.reserveCapacity(44 + dataSize)
        
        // RIFF header
        data.append(contentsOf: "RIFF".utf8)
        appendUInt32(&data, UInt32(36 + dataSize))
        data.append(contentsOf: "WAVE".utf8)
        
        // fmt chunk
        data.append(contentsOf: "fmt ".utf8)
        appendUInt32(&data, 16)
        appendUInt16(&data, 1) // PCM
        appendUInt16(&data, numChannels)
        appendUInt32(&data, UInt32(sampleRate))
        appendUInt32(&data, UInt32(sampleRate * Double(numChannels) * Double(bytesPerSample)))
        appendUInt16(&data, numChannels * UInt16(bytesPerSample))
        appendUInt16(&data, bitsPerSample)
        
        // data chunk
        data.append(contentsOf: "data".utf8)
        appendUInt32(&data, UInt32(dataSize))
        
        let freqL = carrierHz
        let freqR = carrierHz + beatHz
        
        // Brown noise state (integrated white noise → deep warm rumble)
        var rng = SimpleRNG(seed: 42)
        var brownL: Double = 0
        var brownR: Double = 0
        let brownDecay = 0.995 // higher = deeper, smoother rumble
        
        // Slow ambient swell period — must divide evenly into duration for seamless loop
        let swellHz = 0.07
        let swellCycles = max(1, Int((Double(frameCount) / sampleRate) * swellHz))
        let swellFreq = Double(swellCycles) / (Double(frameCount) / sampleRate)
        
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            
            // --- Left ear: carrier frequency ---
            var left = sin(2.0 * .pi * freqL * t)
            // Minimal 2nd harmonic — just enough body, not organ-like
            left += warmth * sin(2.0 * .pi * freqL * 2.0 * t)
            left *= toneAmp
            
            // --- Right ear: carrier + beat frequency ---
            var right = sin(2.0 * .pi * freqR * t)
            right += warmth * sin(2.0 * .pi * freqR * 2.0 * t)
            right *= toneAmp
            
            // --- Deep brown noise bed (uncorrelated L/R) ---
            brownL = brownDecay * brownL + (1.0 - brownDecay) * rng.next()
            brownR = brownDecay * brownR + (1.0 - brownDecay) * rng.next()
            left  += brownL * noiseAmp
            right += brownR * noiseAmp
            
            // --- Slow ambient swell (~0.07Hz): multiplier 0.75–1.0 ---
            let swell = 0.875 + 0.125 * cos(2.0 * .pi * swellFreq * t)
            left  *= swell
            right *= swell
            
            // --- Gentle fade at loop boundary (50ms crossfade) ---
            let fadeSamples = Int(0.05 * sampleRate)
            let fadeIn: Double
            if i < fadeSamples {
                fadeIn = Double(i) / Double(fadeSamples)
            } else if i > frameCount - fadeSamples {
                fadeIn = Double(frameCount - i) / Double(fadeSamples)
            } else {
                fadeIn = 1.0
            }
            left  *= fadeIn
            right *= fadeIn
            
            // Clamp and write interleaved stereo: L, R, L, R...
            let clampL = max(-1.0, min(1.0, left))
            let clampR = max(-1.0, min(1.0, right))
            appendInt16(&data, Int16(clampL * Double(Int16.max)))
            appendInt16(&data, Int16(clampR * Double(Int16.max)))
        }
        
        return data
    }
    
    /// Greatest common divisor for frequency alignment
    private func gcd(_ a: Double, _ b: Double) -> Double {
        let precision = 1000.0
        let ai = Int(a * precision)
        let bi = Int(b * precision)
        var x = ai, y = bi
        while y != 0 { let temp = y; y = x % y; x = temp }
        return Double(x) / precision
    }
    
    // MARK: - WAV Helpers
    
    private func appendUInt16(_ data: inout Data, _ value: UInt16) {
        var v = value.littleEndian
        data.append(Data(bytes: &v, count: 2))
    }
    
    private func appendUInt32(_ data: inout Data, _ value: UInt32) {
        var v = value.littleEndian
        data.append(Data(bytes: &v, count: 4))
    }
    
    private func appendInt16(_ data: inout Data, _ value: Int16) {
        var v = value.littleEndian
        data.append(Data(bytes: &v, count: 2))
    }
    
    // MARK: - Playback
    
    func startAmbient() {
        guard !isPlaying else { return }
        
        calmPlayer?.play()
        stressPlayer?.play()
        isPlaying = true
    }
    
    func stopAmbient() {
        calmPlayer?.stop()
        stressPlayer?.stop()
        isPlaying = false
    }
    
    func updateForScore(_ score: Double) {
        guard isPlaying, !isMuted else { return }
        
        let normalizedScore = min(max(score, 0), 100) / 100.0
        
        // Calm fades out as stress rises
        calmPlayer?.volume = Float(1.0 - normalizedScore * 0.6)
        stressPlayer?.volume = Float(normalizedScore * 0.7)
    }
    
    func setFocusMode(_ enabled: Bool) {
        if enabled {
            stressPlayer?.volume = 0
            calmPlayer?.volume = 0.8
        }
    }
    
    func playEventChime() {
        guard isPlaying, !isMuted else { return }
        let originalVolume = calmPlayer?.volume ?? 0.6
        calmPlayer?.volume = min(originalVolume + 0.3, 1.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.calmPlayer?.volume = originalVolume
        }
    }
    
    func playCompletionChime() {
        guard !isMuted else { return }
        let originalVolume = calmPlayer?.volume ?? 0.6
        calmPlayer?.volume = 1.0
        stressPlayer?.volume = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.calmPlayer?.volume = originalVolume
        }
    }
}
