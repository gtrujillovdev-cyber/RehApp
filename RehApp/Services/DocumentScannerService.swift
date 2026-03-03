import Foundation
import Vision
import PDFKit

protocol DocumentScannerServiceProtocol: Sendable {
    func scanPDF(url: URL) async throws -> String
}

final class DocumentScannerService: DocumentScannerServiceProtocol {
    func scanPDF(url: URL) async throws -> String {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw NSError(domain: "DocumentScannerService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load PDF"])
        }
        
        var recognizedText = ""
        
        for i in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: i) else { continue }
            let pageContent = page.string ?? ""
            
            if pageContent.isEmpty {
                // Future: OCR logic for image-only PDFs
                recognizedText += ""
            } else {
                recognizedText += pageContent
            }
        }
        
        return recognizedText
    }
}
