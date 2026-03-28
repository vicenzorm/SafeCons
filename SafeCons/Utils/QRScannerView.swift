//
//  QRScannerView.swift
//  SafeCons
//
//  Created by Vicenzo Másera on 27/03/26.
//
import SwiftUI
import Vision
import VisionKit

struct QRScannerView: UIViewControllerRepresentable {
    var didFindCode: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .fast,
            recognizesMultipleItems: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: QRScannerView
        
        init(_ parent: QRScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let item = addedItems.first,
               case let .barcode(barcode) = item,
               let stringValue = barcode.payloadStringValue {
                dataScanner.stopScanning()
                parent.didFindCode(stringValue)
            }
        }
    }
}
