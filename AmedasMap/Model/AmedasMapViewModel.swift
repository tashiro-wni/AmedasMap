//
//  AmedasMapViewModel.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation
import MapKit

// MARK: - AmedasMapViewModel
final class AmedasMapViewModel: NSObject, ObservableObject {
    @Published private(set) var amedasPoints: [String: AmedasPoint] = [:]
    @Published private(set) var amedasData: [AmedasData] = []
    @Published private(set) var date: Date?
    var dateText: String {
        if let date = date {
            return dateFormatter.string(from: date)
        } else {
            return "Loading..."
        }
    }
    @Published private(set) var errorMessage = "" {
        didSet {
            hasError = !errorMessage.isEmpty
        }
    }
    @Published var hasError = false
    @Published var displayElement: AmedasElement = .temperature

    private var annotations: [MKAnnotation] = []
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d HH:mm"
        dateFormatter.locale = LocalePOSIX
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()
    
    // MARK: -
    override init() {
        super.init()
        loadPoints()
        loadData()
    }
    
    // 地点リストを読み込み
    private func loadPoints() {
        errorMessage = ""

        AmedasTableLoader().load() { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let points):
                    LOG("update amedasPoints \(points.count) points.")
                    self?.amedasPoints = points
                    
                case .failure:
                    self?.errorMessage = "データが読み込めませんでした。"
                }
            }
        }
    }
    
    // 最新の観測データを読み込み
    func loadData() {
        LOG(#function)
        errorMessage = ""

        AmedasDataLoader().load() { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    self.amedasData = data.data
                    self.date = data.date
                    LOG("update amedasData \(self.dateText), \(data.data.count) points.")

                case .failure:
                    self.errorMessage = "データが読み込めませんでした。"
                }
            }
        }
    }

    func registerAnnotationViews(mapView: MKMapView) {
        for identifier in AmedasData.allIdentifiers {
            mapView.register(AmedasAnnotationView.self, forAnnotationViewWithReuseIdentifier: identifier)
        }
    }

    func updateAnnotations(mapView: MKMapView) {
        mapView.removeAnnotations(annotations)
        annotations.removeAll()
        
        for data in amedasData {
            if let point = amedasPoints[data.pointID], data.hasValidData(for: displayElement) {
                annotations.append(AmedasAnnotation(point: point, data: data, element: displayElement))
            }
        }
        LOG(#function + ", \(dateText), \(displayElement), plot \(annotations.count) points.")
        mapView.addAnnotations(annotations)
        mapView.setNeedsDisplay()
    }
}

extension AmedasMapViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let amedas = annotation as? AmedasAnnotation,
              let reuseIdentifier = amedas.amedasData.reuseIdentifier(for: displayElement) else { return nil }
        
        return mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation)
    }
}
