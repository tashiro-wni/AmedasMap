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
        VStack(spacing: 0) {
            Text(pointName)
                .font(.title)
                .padding(12)
            // 選択地点のデータを時刻の新しい順に取り出し、正時(00分)のデータを24個取り出す
            List(viewModel.selectedPointData.reversed().filter{ $0.is0min }.prefix(24), id: \.self) { item in
                Text(formattedText(item))
                    .lineLimit(1)
                
            }
            .listStyle(.plain)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
    }
    
    private func formattedText(_ item: AmedasData) -> String {
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
