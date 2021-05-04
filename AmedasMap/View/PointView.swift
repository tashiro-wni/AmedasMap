//
//  PointView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/05/04.
//

import SwiftUI

struct PointView: View {
    @StateObject var viewModel: AmedasMapViewModel

    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        dateFormatter.locale = LocalePOSIX
        dateFormatter.timeZone = TimeZoneJST
        return dateFormatter
    }()

    private var pointName: String {
        String(format: "%@(%@)",
               viewModel.amedasPoints[viewModel.selectedPoint]?.pointNameJa ?? "",
               viewModel.selectedPoint) }

    var body: some View {
        VStack {
            Text(pointName)
                .font(.title)
            List(viewModel.selectedPointData.reversed().filter{ $0.is0min }.prefix(24), id: \.self) { item in
                Text(formattedText(item))
                    .lineLimit(1)
            }
        }
    }
    
    func formattedText(_ item: AmedasData) -> String {
        var texts: [String] = []
        texts.append(dateFormatter.string(from: Date(timeIntervalSince1970: item.time)))
        if item.hasValidData(for: .temperature) {
            texts.append("🌡" + item.text(for: .temperature))
        }
        if item.text(for: .precipitation) != item.invalidText {
            texts.append("☂️" + item.text(for: .precipitation))
        }
        if item.hasValidData(for: .wind) {
            texts.append("🎐" + item.text(for: .wind))
        }
        return texts.joined(separator: ", ")
    }
}
