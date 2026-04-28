import Flutter
import UIKit
import PDFKit

public class PdfAnnotationsPlugin: NSObject, FlutterPlugin, PdfAnnotationsApi {
    
    static var fontNameMapping: [String: String] = [:]
    
    public static func register(with registrar: any FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let api : PdfAnnotationsApi & NSObjectProtocol = PdfAnnotationsPlugin.init()
        PdfAnnotationsApiSetup.setUp(binaryMessenger: messenger, api: api)
    }
    
    func registerFonts(fontList: [String]) throws -> Bool {
        let bundle = Bundle.main
        var fontMapping: [String: String] = [:]
        
        for fileName in fontList {
            let fontKey = FlutterDartProject.lookupKey(forAsset: "fonts/\(fileName)", from: bundle)
            guard let path = bundle.path(forResource: fontKey, ofType: nil) else {
                throw AnnotationsError(code: "FAIL", message: "Path not found for font: \(fileName)", details: "nil")
            }
            
            // Load the font data
            guard let fontData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                throw AnnotationsError(code: "FAIL", message: "Failed to load font data for font: \(fileName)", details: "nil")
            }
            
            // Create data provider
            guard let dataProvider = CGDataProvider(data: fontData as CFData) else {
                throw AnnotationsError(code: "FAIL", message: "Failed to create data provider for font: \(fileName)", details: "nil")
            }
            
            // Create CGFont reference
            guard let fontRef = CGFont(dataProvider) else {
                throw AnnotationsError(code: "FAIL", message: "Failed to create CGFont reference for font: \(fileName)", details: "nil")
            }

            guard let postScriptName = fontRef.postScriptName as String? else {
                throw AnnotationsError(code: "FAIL", message: "Could not retrieve PostScript name for \(fileName)", details: "nil")
            }

            if UIFont(name: postScriptName, size: 1) == nil {
                var errorRef: Unmanaged<CFError>?
                if !CTFontManagerRegisterGraphicsFont(fontRef, &errorRef) {
                    if let error = errorRef?.takeRetainedValue() {
                        throw AnnotationsError(code: "FAIL", message: "Failed to register font: \((error as Error).localizedDescription)", details: "nil")
                    } else {
                        throw AnnotationsError(code: "FAIL", message: "Unknown error registering font: \(fileName)", details: "nil")
                    }
                }
            }

            fontMapping[fileName] = postScriptName
        }
        PdfAnnotationsPlugin.fontNameMapping = fontMapping
        
        return true
    }
    
    func addAnnotations(annotationData: AnnotationData) throws -> Bool {
        let fileName = annotationData.fileName
        let flutterPdfPageWidth = annotationData.pdfPageWidth
        let flutterPdfPageHeight = annotationData.pdfPageHeight
        
        let url = URL(fileURLWithPath: fileName)
        guard let document : PDFDocument = PDFDocument(url: url) else {
            throw AnnotationsError(code: "FAIL", message: "PDF document not found at path: \(fileName)", details: "nil")
        }
        let noOfPages = document.pageCount
        
        for pageNo in 0..<(noOfPages) {
            guard let page : PDFPage = document.page(at: pageNo) else {
                throw AnnotationsError(code: "FAIL", message: "Failed to retrieve page number: \(pageNo)", details: "nil")
            }
            let pageMediaBox : CGRect = page.bounds(for: PDFDisplayBox.mediaBox)
            let pdfBoxPageWidth = pageMediaBox.width
            let pdfBoxPageHeight = pageMediaBox.height
            let scalingX = pdfBoxPageWidth / flutterPdfPageWidth
            let scalingY = pdfBoxPageHeight / flutterPdfPageHeight
            let pageHeightOffset = (Double(noOfPages - pageNo - 1)) * flutterPdfPageHeight
            do {
                if let drawingPaths = annotationData.drawingPaths {
                    try addDrawingAnnotations(drawingPaths, pageMediaBox, scalingX, scalingY, pageHeightOffset, flutterPdfPageHeight, page)
                }
                if let textAnnotations = annotationData.textAnnotations {
                    try addTextAnnotations(textAnnotations, scalingX, scalingY, pageHeightOffset, flutterPdfPageHeight, page)
                }
            } catch let error as AnnotationsError {
                throw error
            } catch {
                throw AnnotationsError(code: "FAIL", message: "Unexpected error: \(error.localizedDescription)", details: "nil")
            }
        }
        
        let writeSuccess = document.write(to: url)
        if !writeSuccess {
            throw AnnotationsError(code: "FAIL", message: "Failed to write the updated PDF document to path: \(fileName)", details: "nil")
        }
        
        return true
    }
    
    fileprivate func addDrawingAnnotations(_ drawingPaths: [[String : Any]], _ mediaBox: CGRect, _ scalingX: Double, _ scalingY: Double,
                                           _ pageHeightOffset: Double, _ pdfPageHeight: Double, _ page: PDFPage) throws {
        for drawnPath in drawingPaths {
            let path = drawnPath["path"] as? [[CGFloat]] ?? [[0.0, 0.0]]
            let width = drawnPath["width"] as? CGFloat ?? 0.0
            
            let bezierPath = UIBezierPath()
            for pointArray in path {
                guard pointArray.count >= 2 else { continue }
                
                let xCoord = pointArray[0] * scalingX
                let yCoord = (pointArray[1] - pageHeightOffset) * scalingY
                if (yCoord >= -width && yCoord <= pdfPageHeight + width) {
                    let point = CGPoint(x: xCoord, y: yCoord)
                    if bezierPath.isEmpty {
                        bezierPath.move(to: point)
                    } else {
                        bezierPath.addLine(to: point)
                    }
                }
            }
            
            if bezierPath.isEmpty {
                continue
            }
            
            let drawingAnnotation = PDFAnnotation(bounds: mediaBox, forType: .ink, withProperties: nil)
            let colourComponents = (drawnPath["colour"] as? [CGFloat])?.prefix(4) ?? [1, 0, 0, 0]
            drawingAnnotation.color = UIColor(red: colourComponents[1] / 255.0,
                                              green: colourComponents[2] / 255.0,
                                              blue: colourComponents[3] / 255.0,
                                              alpha: colourComponents[0] / 255.0)
            let lineBorder = PDFBorder()
            lineBorder.lineWidth = width
            drawingAnnotation.border = lineBorder
            drawingAnnotation.add(bezierPath)
            page.addAnnotation(drawingAnnotation)
        }
    }
    
    
    fileprivate func addTextAnnotations(_ textAnnotations: [[String : Any]], _ scalingX: Double, _ scalingY: Double, _ pageHeightOffset: Double, _ pdfPageHeight: Double, _ page: PDFPage) throws {
        for textAnnotation in textAnnotations {
            let coordinate = (textAnnotation["coordinate"] as? [CGFloat])?.prefix(2) ?? [0.0, 0.0]
            let textString = textAnnotation["text_string"] as? String ?? ""
            guard let fontName = textAnnotation["font_name"] as? String, !fontName.isEmpty else {
                throw AnnotationsError(code: "FAIL", message: "Missing font name for text annotation.", details: "nil")
            }
            let fontSize = textAnnotation["font_size"] as? CGFloat ?? 12.0
            guard let postScriptName = PdfAnnotationsPlugin.fontNameMapping[fontName] else {
                throw AnnotationsError(code: "FAIL", message: "No PostScript name found for font file: \(fontName)", details: "nil")
            }
            guard let customFont = UIFont(name: postScriptName, size: fontSize) else {
                throw AnnotationsError(code: "FAIL", message: "Failed to load font with PostScript name: \(postScriptName)", details: "nil")
            }
            let annotationSize = sizeForTextAnnotation(text: textString, font: customFont)
            let xCoord = coordinate[0] * scalingX
            let yCoord = (coordinate[1] - pageHeightOffset) * scalingY - annotationSize.height
            
            if (yCoord >= -annotationSize.height && yCoord <= pdfPageHeight + annotationSize.height) {
                let bounds = CGRect(origin: CGPoint(x: xCoord, y: yCoord), size: annotationSize)
                let colour = (textAnnotation["colour"] as? [CGFloat])?.prefix(4) ?? [1, 0, 0, 0]
                addTextAnnotation(textString, bounds, colour, page, customFont)
            }
        }
    }
    
    fileprivate func addTextAnnotation(_ textString: String, _ bounds: CGRect, _ colour: ArraySlice<CGFloat>, _ page: PDFPage, _ customFont: UIFont) {
        
        let pdfTextAnnotation = PDFAnnotation(bounds: bounds, forType: .freeText, withProperties: nil)
        pdfTextAnnotation.fontColor = UIColor(red: colour[1] / 255.0,
                                              green: colour[2] / 255.0,
                                              blue: colour[3] / 255.0,
                                              alpha: colour[0] / 255.0)
        pdfTextAnnotation.color = .clear
        pdfTextAnnotation.font = customFont
        pdfTextAnnotation.contents = textString
        page.addAnnotation(pdfTextAnnotation)
    }
    
    fileprivate func sizeForTextAnnotation(text: String, font: UIFont) -> CGSize {
        let attributedString = NSAttributedString(string: text, attributes: [.font: font])
        let boundingBox = attributedString.boundingRect(with: CGSize.zero, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        
        let padding : CGFloat = 5
        return CGSize(width: ceil(boundingBox.width) + padding, height: ceil(boundingBox.height) + padding)
    }
    
    func undoAnnotation(fileName: String, pageNo: Int64) throws -> Bool {
        guard !fileName.isEmpty else {
            throw AnnotationsError(code: "FAIL", message: "Empty file name provided", details: "nil")
        }
        guard pageNo >= 0 else {
            throw AnnotationsError(code: "FAIL", message: "Page number must be non-negative", details: "nil")
        }
        
        let url = URL(fileURLWithPath: fileName)
        
        guard let document : PDFDocument = PDFDocument(url: url) else {
            throw AnnotationsError(code: "FAIL", message: "PDF document not found at path: \(fileName)", details: "nil")
        }
        
        let pageCount = document.pageCount
        
        guard pageNo < pageCount else {
            throw AnnotationsError(code: "FAIL", message: "Page number \(pageNo) exceeds document page count (\(pageCount))", details: "nil")
        }
        guard let page : PDFPage = document.page(at: Int(pageNo)) else {
            throw AnnotationsError(code: "FAIL", message: "Failed to retrieve page number: \(pageNo)", details: "nil")
        }
        
        let annotations = page.annotations
        if (annotations.isEmpty) {
            return false
        }
            
        let lastAnnotation = annotations.last!
        page.removeAnnotation(lastAnnotation)
        
        let writeSuccess = document.write(to: url)
        if !writeSuccess {
            throw AnnotationsError(code: "FAIL", message: "Failed to write the updated PDF document to path: \(fileName)", details: "nil")
        }
        
        return true
    }
}
