//
//  PointView.swift
//  AmedasMap
//
//  Created by tasshy on 2021/05/04.
//

import SwiftUI

struct PointView: View {
    @StateObject var viewModel: AmedasMapViewModel

    private var pointName: String {
        String(format: "%@(%@)",
               viewModel.amedasPoints[viewModel.selectedPoint]?.pointNameJa ?? "",
               viewModel.selectedPoint) }

    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "H:mm"
        dateFormatter.locale = .posix
        dateFormatter.timeZone = .jst
        return dateFormatter
    }()

    private func isLandscape(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > geometry.size.height
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Text(pointName)
                    .font(.title)
                    .padding(12)

                // 表で表示する
                Grid(alignment: .trailing) {
                    // 選択地点のデータを時刻の新しい順に取り出し、正時(00分)のデータを24個取り出す
                    ForEach(viewModel.selectedPointData.reversed().filter{ $0.is0min }.prefix(24), id: \.self) { item in
                        GridRow() {
                            Text(dateFormatter.string(from: Date(timeIntervalSince1970: item.time)))

                            if item.hasValidData(for: .temperature) {
                                Text(item.text(for: .temperature))
                            }
                            if item.text(for: .precipitation) != item.invalidText {
                                Text(item.text(for: .precipitation))
                            }
                            if item.hasValidData(for: .wind) {
                                Text(item.text(for: .wind))
                            }
                            if isLandscape(geometry), item.hasValidData(for: .sun) {
                                Text(item.text(for: .sun))
                            }
                            if isLandscape(geometry), item.hasValidData(for: .humidity) {
                                Text(item.text(for: .humidity))
                            }
                            if isLandscape(geometry), item.hasValidData(for: .pressure) {
                                Text(item.text(for: .pressure))
                            }
                            Spacer()
                        }
                        .lineLimit(1)

                        Divider()
                    }
                }
            }
        }
    }
}
