import SwiftUI
import AVFoundation

@main
struct DPISplitterApp: App {
    init() {
        BackgroundKeeper.shared.startSilentAudio()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Генерирует пустой WAV-буфер прямо в ОЗУ, чтобы iOS держала сокет в фоне бесконечно
class BackgroundKeeper {
    static let shared = BackgroundKeeper()
    private var player: AVAudioPlayer?

    func startSilentAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // Минимальный валидный WAV-файл (44 байта заголовка + тишина)
            let sampleRate: Int32 = 8000
            let numSamples: Int32 = 8000
            var wav = Data()
            wav.append("RIFF".data(using: .ascii)!)
            var chunkSize: Int32 = 36 + numSamples * 2
            wav.append(Data(bytes: &chunkSize, count: 4))
            wav.append("WAVEfmt ".data(using: .ascii)!)
            var subchunk1Size: Int32 = 16
            var audioFormat: Int16 = 1
            var numChannels: Int16 = 1
            var byteRate: Int32 = sampleRate * 2
            var blockAlign: Int16 = 2
            var bitsPerSample: Int16 = 16
            wav.append(Data(bytes: &subchunk1Size, count: 4))
            wav.append(Data(bytes: &audioFormat, count: 2))
            wav.append(Data(bytes: &numChannels, count: 2))
            var sr = sampleRate
            wav.append(Data(bytes: &sr, count: 4))
            wav.append(Data(bytes: &byteRate, count: 4))
            wav.append(Data(bytes: &blockAlign, count: 2))
            wav.append(Data(bytes: &bitsPerSample, count: 2))
            wav.append("data".data(using: .ascii)!)
            var subchunk2Size: Int32 = numSamples * 2
            wav.append(Data(bytes: &subchunk2Size, count: 4))
            wav.append(Data(count: Int(subchunk2Size)))

            player = try AVAudioPlayer(data: wav, fileTypeHint: AVFileType.wav.rawValue)
            player?.numberOfLoops = -1
            player?.volume = 0.01
            player?.play()
        } catch {
            print("Background audio error: \(error)")
        }
    }
}
