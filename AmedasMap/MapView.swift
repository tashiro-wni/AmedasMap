//
//  MapView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/02/28.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    typealias UIViewType = MKMapView
    let mapView = MKMapView()

    @StateObject var viewModel: AmedasMapViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        //LOG(#function)
        mapView.delegate = context.coordinator
        mapView.mapType = .mutedStandard
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.681, longitude: 139.767),
                                            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0))
        context.coordinator.registerAnnotationViews()
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        //LOG(#function)
        context.coordinator.updateAnnotations(viewModel: viewModel)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Coordinator
// https://www.hackingwithswift.com/forums/swiftui/update-mapview-with-current-location-on-swiftui/1074
// https://github.com/vvvegesna/MeetupReminder
final class Coordinator: NSObject, MKMapViewDelegate {
    private let parent: MapView
    private var annotations: [MKAnnotation] = []

    init(_ parent: MapView) {
        self.parent = parent
        super.init()
    }
    
    func registerAnnotationViews() {
        for identifier in AmedasData.allIdentifiers {
            parent.mapView.register(AmedasAnnotationView.self, forAnnotationViewWithReuseIdentifier: identifier)
        }
    }

    func updateAnnotations(viewModel: AmedasMapViewModel) {
        parent.mapView.removeAnnotations(annotations)
        annotations.removeAll()
        
        for data in viewModel.amedasData {
            if let point = viewModel.amedasPoints[data.pointID], data.hasValidData(for: viewModel.displayElement) {
                annotations.append(AmedasAnnotation(point: point, data: data, element: viewModel.displayElement))
            }
        }
        LOG(#function + ", \(viewModel.dateText), \(viewModel.displayElement), plot \(annotations.count) points.")
        parent.mapView.addAnnotations(annotations)
        parent.mapView.setNeedsDisplay()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //LOG(#function)
        guard let amedas = annotation as? AmedasAnnotation,
              let reuseIdentifier = amedas.amedasData.reuseIdentifier(for: parent.viewModel.displayElement),
              let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation) as? AmedasAnnotationView else { return nil }

        view.point = amedas.point
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let amedasView = view as? AmedasAnnotationView,
              let point = amedasView.point else { return }
        LOG(#function + ", \(point.pointNameJa)")
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let amedasView = view as? AmedasAnnotationView,
              let point = amedasView.point else { return }
        LOG(#function + ", \(point.pointNameJa)")
    }
}
