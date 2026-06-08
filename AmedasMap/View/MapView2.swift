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

struct MapView2: View {
    @Environment(AmedasMapViewModel.self) private var viewModel
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        // Map の @MapContentBuilder 内のアクセスは @Observable の依存として
        // 登録されないため、body スコープで読み出して依存を確定させる
        let displayElement = viewModel.displayElement
        let amedasData = viewModel.amedasData
        let amedasPoints = viewModel.amedasPoints

        Map(position: $position,
            interactionModes: MapInteractionModes(arrayLiteral: [ .pan, .zoom ] )) {

            // アイコンプロット
            ForEach(amedasData) { data in
                if let point = amedasPoints[data.pointID],
                   data.hasValidData(for: displayElement),
                   let icon = data.makeIcon(for: displayElement) {
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
