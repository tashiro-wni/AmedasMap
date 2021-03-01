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
        guard let temperature = temperature else { return .lightGray }
        switch temperature {
        case -50 ..< -5: return .white
        case -5 ..< 0:   return .purple
        case  0 ..< 5:   return .blue
        case  5 ..< 10:  return .cyan
        case 10 ..< 15:  return .green
        case 15 ..< 20:  return .yellow
        case 20 ..< 25:  return .orange
        case 25 ..< 50:  return .red
        default:  return .lightGray
        }
    }
}

final class AmedasAnnotation: MKPointAnnotation {
    let amedasData: AmedasData
    
    init(point: AmedasPoint, data: AmedasData) {
        amedasData = data
        super.init()
        coordinate = point.coordinate
        title = point.pointNameJa
        if let temperature = data.temperature {
            subtitle = String(format: "%.1f℃", temperature)
        } else {
            subtitle = "-"
        }
    }
}

final class AmedasMapViewModel: NSObject, ObservableObject {
    @Published private(set) var amedasPoints: [String: AmedasPoint] = [:]
    @Published private(set) var amedasData: [AmedasData] = []
    private var annotations: [MKAnnotation] = []
    
    override init() {
        super.init()
        loadPoints()
    }
    
    func loadPoints() {
        AmedasTableLoader().load() { [weak self] result in
            switch result {
            case .success(let points):
                DispatchQueue.main.async { [weak self] in
                    LOG("update amedasPoints \(points.count) points.")
                    self?.amedasPoints = points
                }
            case .failure:
                break
            }
        }
        
        AmedasDataLoader().load() { [weak self] result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async { [weak self] in
                    LOG("update amedasData \(data.count) points.")
                    self?.amedasData = data
                }
            case .failure:
                break
            }
        }
    }
    
    func updateAnnotations(mapView: MKMapView) {
        mapView.removeAnnotations(annotations)
        annotations.removeAll()
        
        for data in amedasData {
            if let point = amedasPoints[data.pointID], data.temperature != nil {
                annotations.append(AmedasAnnotation(point: point, data: data))
            }
        }
        mapView.addAnnotations(annotations)
    }
}

extension AmedasMapViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: "point", for: annotation) as! MKPinAnnotationView
        view.annotation = annotation
        view.canShowCallout = true
        
        if let amedas = annotation as? AmedasAnnotation {
            let color = amedas.amedasData.temperatureColor
            view.pinTintColor = color
            
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
