//
//  AmedasMapViewModel.swift
//  AmedasMap
//
//  Created by tasshy on 2021/03/01.
//

import Foundation
import MapKit

extension AmedasPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension AmedasData {
    private static let temperatureColors = [ "#E60000", "#F254B0", "#FF8800", "#FFD500", "#67CC33",
                                             "#56C6FF", "#3377FF", "#3377FF", "#B2B2B2", "#9522E6" ]

    private static let precipitationColors = [ "#D90000", "#FFBF00", "#002CB2", "#45A3E5", "#999999" ]
    
    private static let windColors = [ "#D90000", "#FF7F00", "#FFBF00", "#5FB235", "#002CB2", "#999999" ]
    
    static var allIdentifiers: [String] {
        var list: [String] = []
        for color in temperatureColors {
            list.append("circle,\(color)")
        }
        for color in precipitationColors {
            list.append("circle,\(color)")
        }
        for dir in 0...16 {
            for color in windColors {
                list.append("arrow,\(dir),\(color)")
            }
        }
        return list
    }
    
    func reuseIdentifier(for element: AmedasElement) -> String? {
        switch element {
        case .temperature:
            guard let temperature = temperature else { return nil }
            switch temperature {
            case  35 ... 50:  return "circle," + Self.temperatureColors[0]
            case  30 ..< 35:  return "circle," + Self.temperatureColors[1]
            case  25 ..< 30:  return "circle," + Self.temperatureColors[2]
            case  20 ..< 25:  return "circle," + Self.temperatureColors[3]
            case  15 ..< 20:  return "circle," + Self.temperatureColors[4]
            case  10 ..< 15:  return "circle," + Self.temperatureColors[5]
            case   5 ..< 10:  return "circle," + Self.temperatureColors[6]
            case   0 ..< 5:   return "circle," + Self.temperatureColors[7]
            case -10 ..< 0:   return "circle," + Self.temperatureColors[8]
            case -50 ..< -10: return "circle," + Self.temperatureColors[9]
            default:  return nil
            }
        case .precipitation:
            guard let precipitation1h = precipitation1h else { return nil }
            switch precipitation1h {
            case 32 ... 500:  return "circle," + Self.precipitationColors[0]
            case 16 ..<  32:  return "circle," + Self.precipitationColors[1]
            case  4 ..<  16:  return "circle," + Self.precipitationColors[2]
            case  1 ..<   4:  return "circle," + Self.precipitationColors[3]
            case  0 ..<   1:  return "circle," + Self.precipitationColors[4]
            default:  return nil
            }
        case .wind:
            guard let windDirection = windDirection, let windSpeed = windSpeed else { return nil }
            switch windSpeed {
            case 25 ... 99:  return "arrow,\(windDirection),\(Self.windColors[0])"
            case 20 ..< 25:  return "arrow,\(windDirection),\(Self.windColors[1])"
            case 15 ..< 20:  return "arrow,\(windDirection),\(Self.windColors[2])"
            case 10 ..< 15:  return "arrow,\(windDirection),\(Self.windColors[3])"
            case  5 ..< 10:  return "arrow,\(windDirection),\(Self.windColors[4])"
            case  0 ..<  5:  return "arrow,\(windDirection),\(Self.windColors[5])"
            default:  return nil
            }
        }
    }
}

final class AmedasAnnotation: MKPointAnnotation {
    let amedasData: AmedasData
    let element: AmedasElement
    
    init(point: AmedasPoint, data: AmedasData, element: AmedasElement) {
        amedasData = data
        self.element = element
        super.init()
        coordinate = point.coordinate
        title = point.pointNameJa

        switch element {
        case .temperature:
            subtitle = data.temperatureText
        case .precipitation:
            subtitle = data.precipitationText
        case .wind:
            subtitle = data.windText
        }
    }
}

final class AmedasMapViewModel: NSObject, ObservableObject {
    @Published private(set) var amedasPoints: [String: AmedasPoint] = [:]
    @Published private(set) var amedasData: [AmedasData] = []
    @Published private(set) var date: Date?
    @Published private(set) var dateText = "Loading..."
    @Published private(set) var errorMessage: String?
    @Published var hasError = false
    @Published var displayElement: AmedasElement = .temperature

    private var annotations: [MKAnnotation] = []
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d HH:mm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()
    
    override init() {
        super.init()
        loadPoints()
        loadData()
    }
    
    func loadPoints() {
        errorMessage = nil
        hasError = false

        AmedasTableLoader().load() { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let points):
                    LOG("update amedasPoints \(points.count) points.")
                    self?.amedasPoints = points
                    
                case .failure:
                    self?.errorMessage = "データが読み込めませんでした。"
                    self?.hasError = true
                }
            }
        }
    }
     
    func loadData() {
        LOG(#function)
        errorMessage = nil
        hasError = false

        AmedasDataLoader().load() { [weak self] result in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    LOG("update amedasData \(data.data.count) points.")
                    self.amedasData = data.data
                    self.date = data.date
                    self.dateText = self.dateFormatter.string(from: data.date)
                    LOG("date: \(self.dateText)")
                case .failure:
                    self.errorMessage = "データが読み込めませんでした。"
                    self.hasError = true
                }
            }
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
        var reuseIdentifier = ""
        if let amedas = annotation as? AmedasAnnotation,
           let identifier = amedas.amedasData.reuseIdentifier(for: displayElement) {
            reuseIdentifier = identifier
        }
        
        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation) as? AmedasAnnotationView {
            view.annotation = annotation
            view.canShowCallout = true
            view.displayPriority = .defaultHigh
            view.collisionMode = .circle
            return view
        }
        
        return nil
    }
}
