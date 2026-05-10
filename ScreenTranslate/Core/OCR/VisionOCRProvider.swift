import Vision
import CoreGraphics
import Foundation
import NaturalLanguage

/// Swift-native Vision API (macOS 15+)의 RecognizeTextRequest를 사용한다.
/// 레거시 VNRecognizeTextRequest 대신 async/await 네이티브 API로 구현.
final class VisionOCRProvider: OCRProvider {
    func recognize(image: CGImage) async throws -> OCRResult {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let observations = try await request.perform(on: image)

        let textsWithConfidence: [(String, Float)] = observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return (candidate.string, candidate.confidence)
        }

        if textsWithConfidence.isEmpty {
            throw OCRError.noTextFound
        }

        let text = textsWithConfidence.map(\.0).joined(separator: "\n")
        let avgConfidence = textsWithConfidence.map(\.1).reduce(0, +) / Float(textsWithConfidence.count)

        // Infer language from the recognized text via NLLanguageRecognizer.
        // Required for downstream features like pinyin display, which gate on
        // result.sourceLanguage (Vision's RecognizeTextRequest does not expose
        // the detected language directly).
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        let detectedLanguage: Locale.Language? = recognizer.dominantLanguage
            .map { Locale.Language(identifier: $0.rawValue) }

        return OCRResult(
            text: text,
            detectedLanguage: detectedLanguage,
            confidence: avgConfidence
        )
    }
}
