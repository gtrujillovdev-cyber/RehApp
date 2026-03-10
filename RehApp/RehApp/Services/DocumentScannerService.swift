import Foundation
import Vision
import PDFKit

/// Errores posibles al procesar un documento.
/// Por qué un enum y no NSError: los enums de Error son idiomatic Swift.
/// NSError existe para compatibilidad con Obj-C, no para código nuevo.
enum DocumentScannerError: LocalizedError {
    case pdfLoadFailed
    case ocrFailed(page: Int)

    var errorDescription: String? {
        switch self {
        case .pdfLoadFailed:      return "No se pudo cargar el PDF."
        case .ocrFailed(let p):   return "Fallo al reconocer texto en la página \(p)."
        }
    }
}

protocol DocumentScannerServiceProtocol: Sendable {
    func scanPDF(url: URL) async throws -> String
}

final class DocumentScannerService: DocumentScannerServiceProtocol {

    func scanPDF(url: URL) async throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw DocumentScannerError.pdfLoadFailed
        }

        var fullText = ""

        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }

            let pageText = page.string ?? ""

            if !pageText.isEmpty {
                // PDF con texto embebido (generado digitalmente): extraemos directo.
                // PDFKit ya parsea el texto del stream interno sin necesidad de IA.
                fullText += pageText
            } else {
                // PDF de imagen (escaneo físico): necesitamos OCR con Vision.
                // La imagen no tiene capa de texto; Vision la procesa píxel a píxel.
                let ocrText = try await performOCR(on: page, pageIndex: i)
                fullText += ocrText
            }
        }

        return fullText
    }

    // MARK: - OCR con Vision Framework

    /// Convierte una página PDF en texto usando reconocimiento óptico de caracteres.
    ///
    /// Por qué `withCheckedContinuation`:
    /// `VNRecognizeTextRequest` funciona con un completion handler (callback).
    /// `withCheckedContinuation` es el puente oficial de Swift para convertir
    /// APIs callback-based en código async/await. La `continuation` actúa como
    /// una "promesa" que se resuelve cuando llamamos a `.resume(returning:)`.
    private func performOCR(on page: PDFPage, pageIndex: Int) async throws -> String {
        guard let pageImage = renderPageAsImage(page) else {
            throw DocumentScannerError.ocrFailed(page: pageIndex)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                // Cada VNRecognizedTextObservation representa una "región de texto"
                // topCandidates(1) devuelve la hipótesis más probable del modelo
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")

                continuation.resume(returning: text)
            }

            // Configuramos el reconocedor para español e inglés (informes médicos bilingües)
            request.recognitionLanguages = ["es-ES", "en-US"]
            // .accurate es más lento pero mejor para textos médicos con terminología compleja
            request.recognitionLevel = .accurate

            let handler = VNImageRequestHandler(cgImage: pageImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Renderiza una página PDF como imagen usando CoreGraphics.
    ///
    /// Por qué CoreGraphics y no UIGraphicsImageRenderer:
    /// UIGraphicsImageRenderer es UIKit — no disponible en macOS.
    /// CGContext funciona en iOS, macOS y visionOS (el proyecto soporta los tres).
    /// Usamos escala 2x para que Vision tenga suficiente resolución de píxeles;
    /// con resolución baja el modelo confunde letras similares (ej. "m" con "rn").
    private func renderPageAsImage(_ page: PDFPage) -> CGImage? {
        let pageRect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let width  = Int(pageRect.width  * scale)
        let height = Int(pageRect.height * scale)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Fondo blanco: Vision no procesa bien el canal alfa (transparente)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: scale, y: scale)

        page.draw(with: .mediaBox, to: context)

        return context.makeImage()
    }
}
