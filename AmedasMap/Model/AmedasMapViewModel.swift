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

final class AmedasMapViewModel: NSObject, ObservableObject {
    @Published private(set) var amedasPoints: [AmedasPoint] = []
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
    }
    
    func updateAnnotations(mapView: MKMapView) {
        mapView.removeAnnotations(annotations)
        annotations.removeAll()
        
        for point in amedasPoints {
            let annotation = MKPointAnnotation()
            annotation.coordinate = point.coordinate
            annotation.title = point.pointNameJa
            annotations.append(annotation)
        }
        mapView.addAnnotations(annotations)
    }
}

extension AmedasMapViewModel: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let view = MKPinAnnotationView()
        view.canShowCallout = true
        return view
    }
}
