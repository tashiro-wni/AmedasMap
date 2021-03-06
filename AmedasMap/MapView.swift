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
    private let mapView = MKMapView()

    @ObservedObject var viewModel: AmedasMapViewModel
    
    func makeUIView(context: Context) -> MKMapView {
        //LOG(#function)
        mapView.delegate = viewModel
        mapView.mapType = .mutedStandard
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.681, longitude: 139.767),
                                            span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0))
        viewModel.registerAnnotationViews(mapView: mapView)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        //LOG(#function)
        viewModel.updateAnnotations(mapView: mapView)
    }
}
