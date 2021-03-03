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
    var temperatureColor: UIColor {
        guard let temperature = temperature else { return .clear }
        switch temperature {
        case  35 ... 50:  return UIColor(hex: 0xe60000)
        case  30 ..< 35:  return UIColor(hex: 0xf254b0)
        case  25 ..< 30:  return UIColor(hex: 0xff8800)
        case  20 ..< 25:  return UIColor(hex: 0xffd500)
        case  15 ..< 20:  return UIColor(hex: 0x67cc33)
        case  10 ..< 15:  return UIColor(hex: 0x56c6ff)
        case   5 ..< 10:  return UIColor(hex: 0x3377ff)
        case   0 ..< 5:   return UIColor(hex: 0x3377ff)
        case -10 ..< 0:   return UIColor(hex: 0xb2b2b2)
        case -50 ..< -10: return UIColor(hex: 0x9522e6)
        default:  return .clear
        }
    }
    
    var precipitationColor: UIColor {
        guard let precipitation1h = precipitation1h else { return .clear }
        switch precipitation1h {
        case 32 ... 500:  return UIColor(hex: 0xd90000)
        case 16 ..<  32:  return UIColor(hex: 0xFFBF00)
        case  4 ..<  16:  return UIColor(hex: 0x002CB2)
        case  1 ..<   4:  return UIColor(hex: 0x45A3E5)
        case  0 ..<   1:  return UIColor(hex: 0x999999)
        default:  return .clear
        }
    }
    
    var windColor: UIColor {
        guard let windSpeed = windSpeed else { return .clear }
        switch windSpeed {
        case 25 ... 99:  return UIColor(hex: 0xd90000)
        case 20 ..< 25:  return UIColor(hex: 0xff7f00)
        case 15 ..< 20:  return UIColor(hex: 0xffbf00)
        case 10 ..< 15:  return UIColor(hex: 0x5fb235)
        case  5 ..< 10:  return UIColor(hex: 0x002cb2)
        case  0 ..<  5:  return UIColor(hex: 0x999999)
        default:  return .clear
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

final class CircleAnnotationView: MKAnnotationView {
    var color: UIColor = .white {
        didSet {
            image = UIImage.circle(size: CGSize(width: 15, height: 15), color: color, borderColor: .white)
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
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "point", for: annotation) as! CircleAnnotationView
        view.annotation = annotation
        view.canShowCallout = true
        
        if let amedas = annotation as? AmedasAnnotation {
            switch displayElement {
            case .temperature:
                view.color = amedas.amedasData.temperatureColor
            case .precipitation:
                view.color = amedas.amedasData.precipitationColor
            case .wind:
                view.color = amedas.amedasData.windColor
            }
            
            
//            // https://stackoverflow.com/questions/58560959/sf-symbols-in-map-wont-apply-colors
//            let image = UIImage(systemName: "circle.fill")!.withTintColor(color)
//            let size = CGSize(width: 20, height: 20)
//            view.image = UIGraphicsImageRenderer(size: size).image {
//                _ in image.draw(in: CGRect(origin: .zero, size: size))
//            }
        }
        
        return view
    }
}
