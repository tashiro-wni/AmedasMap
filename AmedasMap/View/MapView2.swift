//
//  MapView2.swift
//  AmedasMap
//
//  Created by tasshy on 2023/06/19.
//

import SwiftUI
import MapKit

extension AmedasPoint {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

@available(iOS 17.0, *)
struct MapView2: View {
    @EnvironmentObject private var viewModel: AmedasMapViewModel
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        Map(position: $position,
            interactionModes: MapInteractionModes(arrayLiteral: [ .pan, .zoom ] )) {

            // アイコンプロット
            ForEach(viewModel.amedasData) { data in
                if let point = viewModel.amedasPoints[data.pointID],
                   data.hasValidData(for: viewModel.displayElement),
                   let icon = data.makeIcon(for: viewModel.displayElement) {
                    Annotation("", coordinate: point.coordinate) {
                        Image(uiImage: icon)
                            .onTapGesture {
                                viewModel.loadPointData(point.pointID)
                            }
                    }
                }
            }
        }
            .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
    }
}
